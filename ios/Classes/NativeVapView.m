
#import "NativeVapView.h"
#import "UIView+VAP.h"
#import "QGVAPWrapView.h"


@interface NativeVapView : NSObject <FlutterPlatformView, VAPWrapViewDelegate>

- (instancetype)initWithFrame: (CGRect) frame
               viewIdentifier: (int64_t) viewId
                    arguments: (id _Nullable) args
                    mRegistrar: (NSObject<FlutterPluginRegistrar> *) registrar;

- (UIView*) view;

@end


@implementation NativeVapViewFactory {
    NSObject<FlutterPluginRegistrar> * _registrar;
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
    }
    
    return self;
}

- (NSObject<FlutterPlatformView> *)createWithFrame: (CGRect) frame
                                    viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    return [[NativeVapView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args mRegistrar:_registrar];
}

@end

@implementation NativeVapView {
    UIView *_view;
    NSObject<FlutterPluginRegistrar> * _registrar;
    QGVAPWrapView *_wrapView;
    FlutterResult _result;
    //播放中就是ture，其他状态false
    BOOL playStatus;
}

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args mRegistrar:(NSObject<FlutterPluginRegistrar> *) registrar {
    if (self == [super init]) {
        playStatus = false;
        _view = [[UIView alloc] init];
        _registrar = registrar;
        FlutterMethodChannel* channel = [FlutterMethodChannel
            methodChannelWithName:@"flutter_vap_controller"
                  binaryMessenger:registrar.messenger];
        
        [registrar addMethodCallDelegate: self channel:channel];
        
    }
    return self;
}

#pragma mark --flutter调native回调
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    _result = result;
    if ([@"playPath" isEqualToString: call.method]) {
        BOOL mute = NO; // Default value
        int repeatCount = 0; // Default value
        if (call.arguments[@"mute"] != nil) {
            mute = [call.arguments[@"mute"] boolValue];
        }
        if (call.arguments[@"loop"] != nil) {
            repeatCount = [call.arguments[@"loop"] intValue];
        }

        [self playByPath:call.arguments[@"path"] mute:mute repeatCount:repeatCount];
    } else if ([@"playAsset" isEqualToString:call.method]) {
        // Play asset file
        NSString* assetPath = [_registrar lookupKeyForAsset:call.arguments[@"asset"]];
        NSString* path = [[NSBundle mainBundle] pathForResource:assetPath ofType:nil];

        BOOL mute = NO; // Default value
        int repeatCount = 0; // Default value
        if (call.arguments[@"mute"] != nil) {
            mute = [call.arguments[@"mute"] boolValue];
        }
        if (call.arguments[@"loop"] != nil) {
            repeatCount = [call.arguments[@"loop"] intValue];
        }

        [self playByPath:path mute:mute repeatCount:repeatCount];
    } else if ([@"stop" isEqualToString:call.method]) {
        if (_wrapView) {
            [_wrapView removeFromSuperview];
        }
        playStatus = false;
    }
}


- (void)playByPath:(NSString *)path mute:(BOOL)mute repeatCount:(int)repeatCount {
    //限制只能有一个视频在播放
    if (playStatus) {
        return;
    }
    _wrapView = [[QGVAPWrapView alloc] initWithFrame:self.view.bounds];
    _wrapView.center = self.view.center;
    [_wrapView setMute:mute];
    _wrapView.contentMode = UIViewContentModeScaleAspectFill;
    _wrapView.autoDestoryAfterFinish = YES;
    [self.view addSubview:_wrapView];
    [_wrapView playHWDMP4:path repeatCount:repeatCount delegate:self];
}


#pragma mark VAPWrapViewDelegate--播放回调
- (void) vapWrap_viewDidStartPlayMP4:(VAPView *)container{
    playStatus = true;
}

- (void) vapWrap_viewDidFailPlayMP4:(NSError *)error{
    NSDictionary *resultDic = @{@"status":@"failure",@"errorMsg":error.description};
    _result(resultDic);
}

- (void) vapWrap_viewDidStopPlayMP4:(NSInteger)lastFrameIndex view:(VAPView *)container{
    playStatus = false;
}
    
-(void) vapWrap_viewDidFinishPlayMP4:(NSInteger)totalFrameCount view:(VAPView *)container {
    NSDictionary *resultDic = @{@"status":@"complete"};
    _result(resultDic);
    playStatus = false;
}

- (UIView*)view {
    return _view;
}

@end
