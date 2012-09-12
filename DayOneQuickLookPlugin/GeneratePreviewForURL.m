#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#include "markdown.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    @autoreleasepool {
        NSURL *cssURL = [[NSBundle bundleWithIdentifier:@"net.mootoh.DayOneQuickLookPlugin"] URLForResource:@"bootstrap.min.css" withExtension:nil];
        NSError *error = nil;
        NSString *css = [NSString stringWithContentsOfURL:cssURL encoding:NSUTF8StringEncoding error:&error];
        NSMutableDictionary *props = [[NSMutableDictionary alloc] init];
        [props setObject:@"UTF-8" forKey:(NSString *)CFBridgingRelease(kQLPreviewPropertyTextEncodingNameKey)];
        [props setObject:@"text/html" forKey:(__bridge NSString *)kQLPreviewPropertyMIMETypeKey];

        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:(__bridge NSURL *)url];
        NSString *content = @"# ";
        content = [content stringByAppendingString:[dict objectForKey:@"Entry Text"]];
        size_t length = [content lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        char buf[length + 1];
        memcpy(buf, [content UTF8String], sizeof(buf));

        Document *md = mkd_string(buf, (int)sizeof(buf), 0);

        char *out = NULL;
        mkd_compile(md, 0);
        mkd_document(md, &out);
        NSString *htmlString = [NSString stringWithUTF8String:out];
        mkd_cleanup(md);
        htmlString = [htmlString stringByAppendingFormat:@"<style>%@</style>", css];

        QLPreviewRequestSetDataRepresentation(preview, (__bridge CFDataRef)[htmlString dataUsingEncoding:NSUTF8StringEncoding], kUTTypeHTML, (__bridge CFDictionaryRef)props);
    }
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
