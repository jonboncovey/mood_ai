#import "SpeechToTextPlugin.h"
#if __has_include(<speech_to_text/speech_to_text-Swift.h>)
#import <speech_to_text/speech_to_text-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "speech_to_text-Swift.h"
#endif

@implementation SpeechToTextPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSpeechToTextPlugin registerWithRegistrar:registrar];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    [self.instance handleMethodCall:call result:result];
}
@end
