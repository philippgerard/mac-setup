#import <CommonCrypto/CommonDigest.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <sys/stat.h>

static void print_usage(void) {
  fputs(
      "Usage: smime-keychain-helper <check|restore> --pkcs12 <path> "
      "[--keychain <path>] [--trusted-application <path>]\n"
      "\n"
      "Read the PKCS#12 password from standard input. The default target is the\n"
      "current user's login keychain and the default trusted application is Mail.\n",
      stderr);
}

static void fail_message(NSString *message) {
  fprintf(stderr, "S/MIME helper: %s.\n", message.UTF8String);
  exit(1);
}

static void fail_status(NSString *message, OSStatus status) {
  fprintf(
      stderr,
      "S/MIME helper: %s (OSStatus %d).\n",
      message.UTF8String,
      (int)status);
  exit(1);
}

static BOOL is_regular_file(NSString *path) {
  struct stat file_status;
  return lstat(path.fileSystemRepresentation, &file_status) == 0 &&
         S_ISREG(file_status.st_mode) && !S_ISLNK(file_status.st_mode);
}

static NSData *certificate_digest(SecIdentityRef identity) {
  SecCertificateRef certificate = NULL;
  OSStatus status = SecIdentityCopyCertificate(identity, &certificate);
  if (status != errSecSuccess || certificate == NULL) {
    fail_status(@"could not read the identity certificate", status);
  }

  CFDataRef certificate_data = SecCertificateCopyData(certificate);
  CFRelease(certificate);
  if (certificate_data == NULL) {
    fail_message(@"could not encode the identity certificate");
  }

  unsigned char digest[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(
      CFDataGetBytePtr(certificate_data),
      (CC_LONG)CFDataGetLength(certificate_data),
      digest);
  CFRelease(certificate_data);
  return [NSData dataWithBytes:digest length:sizeof(digest)];
}

static SecIdentityRef import_identity(
    NSData *pkcs12_data,
    NSString *password,
    BOOL memory_only,
    SecKeychainRef keychain,
    SecAccessRef access) {
  NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObject:password
                                                                    forKey:(__bridge id)kSecImportExportPassphrase];
  if (memory_only) {
    if (@available(macOS 15.0, *)) {
      options[(__bridge id)kSecImportToMemoryOnly] = @YES;
    } else {
      fail_message(@"memory-only PKCS#12 inspection requires macOS 15 or newer");
    }
  } else {
    if (keychain == NULL || access == NULL) {
      fail_message(@"target keychain access is missing");
    }
    options[(__bridge id)kSecImportExportKeychain] = (__bridge id)keychain;
    options[(__bridge id)kSecImportExportAccess] = (__bridge id)access;
  }

  CFArrayRef raw_items = NULL;
  OSStatus status = SecPKCS12Import(
      (__bridge CFDataRef)pkcs12_data,
      (__bridge CFDictionaryRef)options,
      &raw_items);
  if (status != errSecSuccess || raw_items == NULL) {
    fail_status(@"PKCS#12 decoding or import failed", status);
  }

  NSArray *items = CFBridgingRelease(raw_items);
  NSMutableArray *identities = [NSMutableArray array];
  for (NSDictionary *item in items) {
    id identity = item[(__bridge id)kSecImportItemIdentity];
    if (identity != nil) {
      [identities addObject:identity];
    }
  }
  if (identities.count != 1) {
    fail_message(@"PKCS#12 item must contain exactly one identity");
  }
  return (__bridge_retained SecIdentityRef)identities.firstObject;
}

static BOOL identity_is_present(NSData *digest, SecKeychainRef keychain) {
  NSDictionary *query = @{
    (__bridge id)kSecClass: (__bridge id)kSecClassIdentity,
    (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll,
    (__bridge id)kSecMatchSearchList: @[ (__bridge id)keychain ],
    (__bridge id)kSecReturnRef: @YES
  };
  CFTypeRef raw_result = NULL;
  OSStatus status = SecItemCopyMatching(
      (__bridge CFDictionaryRef)query,
      &raw_result);
  if (status == errSecItemNotFound) {
    return NO;
  }
  if (status != errSecSuccess || raw_result == NULL) {
    fail_status(@"could not inspect identities in the target keychain", status);
  }

  NSArray *identities = CFBridgingRelease(raw_result);
  for (id value in identities) {
    SecIdentityRef identity = (__bridge SecIdentityRef)value;
    if ([certificate_digest(identity) isEqualToData:digest]) {
      return YES;
    }
  }
  return NO;
}

static SecAccessRef create_access(NSString *trusted_application_path) {
  if (![[NSFileManager defaultManager] fileExistsAtPath:trusted_application_path]) {
    fail_message(@"trusted application is missing");
  }

  SecTrustedApplicationRef trusted_application = NULL;
  OSStatus trusted_status = SecTrustedApplicationCreateFromPath(
      trusted_application_path.fileSystemRepresentation,
      &trusted_application);
  if (trusted_status != errSecSuccess || trusted_application == NULL) {
    fail_status(@"could not create the trusted application", trusted_status);
  }

  NSArray *trusted_applications = @[ (__bridge id)trusted_application ];
  SecAccessRef access = NULL;
  OSStatus access_status = SecAccessCreate(
      CFSTR("S/MIME identity for Mail"),
      (__bridge CFArrayRef)trusted_applications,
      &access);
  CFRelease(trusted_application);
  if (access_status != errSecSuccess || access == NULL) {
    fail_status(@"could not create scoped key access", access_status);
  }
  return access;
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    if (argc < 4) {
      print_usage();
      return 2;
    }

    NSString *action = [NSString stringWithUTF8String:argv[1]];
    if (![action isEqualToString:@"check"] && ![action isEqualToString:@"restore"]) {
      print_usage();
      return 2;
    }

    NSString *pkcs12_path = nil;
    NSString *keychain_path = [NSHomeDirectory()
        stringByAppendingPathComponent:@"Library/Keychains/login.keychain-db"];
    NSString *trusted_application_path = @"/System/Applications/Mail.app";
    for (int index = 2; index < argc; index += 2) {
      if (index + 1 >= argc) {
        print_usage();
        return 2;
      }
      NSString *option = [NSString stringWithUTF8String:argv[index]];
      NSString *value = [NSString stringWithUTF8String:argv[index + 1]];
      if ([option isEqualToString:@"--pkcs12"]) {
        pkcs12_path = value;
      } else if ([option isEqualToString:@"--keychain"]) {
        keychain_path = value;
      } else if ([option isEqualToString:@"--trusted-application"]) {
        trusted_application_path = value;
      } else {
        print_usage();
        return 2;
      }
    }

    if (pkcs12_path == nil || !is_regular_file(pkcs12_path)) {
      fail_message(@"PKCS#12 input must be a regular file");
    }
    if (!is_regular_file(keychain_path)) {
      fail_message(@"target keychain must be a regular file");
    }

    NSData *pkcs12_data = [NSData dataWithContentsOfFile:pkcs12_path
                                                 options:NSDataReadingMappedIfSafe
                                                   error:NULL];
    if (pkcs12_data == nil || pkcs12_data.length == 0 ||
        pkcs12_data.length > 16 * 1024 * 1024) {
      fail_message(@"PKCS#12 input is empty or unexpectedly large");
    }

    NSData *password_data = [[NSFileHandle fileHandleWithStandardInput]
        readDataToEndOfFile];
    if (password_data.length == 0 || password_data.length > 65 * 1024 ||
        memchr(password_data.bytes, '\0', password_data.length) != NULL) {
      fail_message(@"PKCS#12 password input is empty or invalid");
    }
    NSString *password = [[NSString alloc] initWithData:password_data
                                               encoding:NSUTF8StringEncoding];
    if (password == nil) {
      fail_message(@"PKCS#12 password input is not valid UTF-8");
    }

    SecKeychainRef keychain = NULL;
    OSStatus keychain_status = SecKeychainOpen(
        keychain_path.fileSystemRepresentation,
        &keychain);
    if (keychain_status != errSecSuccess || keychain == NULL) {
      fail_status(@"could not open the requested keychain", keychain_status);
    }

    SecIdentityRef memory_identity = import_identity(
        pkcs12_data,
        password,
        YES,
        NULL,
        NULL);
    NSData *digest = certificate_digest(memory_identity);
    CFRelease(memory_identity);

    if (identity_is_present(digest, keychain)) {
      puts("present");
      CFRelease(keychain);
      return 0;
    }
    if ([action isEqualToString:@"check"]) {
      puts("missing");
      CFRelease(keychain);
      return 0;
    }

    SecAccessRef access = create_access(trusted_application_path);
    SecIdentityRef imported_identity = import_identity(
        pkcs12_data,
        password,
        NO,
        keychain,
        access);
    CFRelease(imported_identity);
    CFRelease(access);
    if (!identity_is_present(digest, keychain)) {
      CFRelease(keychain);
      fail_message(@"identity was not found after import");
    }

    puts("imported");
    CFRelease(keychain);
    return 0;
  }
}
