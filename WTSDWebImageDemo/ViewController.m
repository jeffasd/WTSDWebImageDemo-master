//
//  ViewController.m
//  WTSDWebImageDemo
//
//  Created by ZZWangtao on 14-12-12.
//  Copyright (c) 2014年 ZZWangtao. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"
#import "OptionsViewController.h"
#import "ModalAnimation.h"
#define USER_DEFAULTS_GENERAL_ENABLED @"GeneralEnabled"
#define USER_DEFAULTS_BLOCK_ENABLED @"BlockEnabled"
#define USER_DEFAULTS_PLACEHOLDER_ENABLED @"PlaceHolderEnabled"
@interface ViewController () <UIViewControllerTransitioningDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UILabel *progressLabel;


@end

@implementation ViewController
{
    // 模态的自定义动画
    ModalAnimation *_modalAnimationController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"SDWebImage";
    // 初始化模态动画
    _modalAnimationController = [[ModalAnimation alloc] init];
    
}

// 隐藏状态栏
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - customMethod
- (IBAction)clearAction:(UIButton *)sender {
    
    // 清除磁盘缓存
    [[SDImageCache sharedImageCache] clearDisk];
    
    // 清除内存缓存
    [[SDImageCache sharedImageCache] clearMemory];
    
    self.imageView.image = nil;
    self.progressView.progress = 0.0;
    self.progressLabel.text = nil;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"清除成功！" preferredStyle:UIAlertControllerStyleAlert];
    [self.navigationController presentViewController:alert animated:YES completion:^{
        
        // 提示消失
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

// 点击加载图片
- (IBAction)imageCache:(UIButton *)sender {
    
    // 图片链接
    NSURL *imageURL = [NSURL URLWithString:@"http://b378.photo.store.qq.com/psb?/V12Li27p14RJo5/209XOMwO2m7N*wMM33HNywzNK4rglaLcgPl4Vynew5M!/b/dOxcUeG1OgAA&bo=VQOAAgAAAAABAPM!&rf=viewer_4"];
    // 占位图片
    UIImage *img = [UIImage imageNamed:@"default.jpeg"];
    
    // 获取开关状态
    BOOL isGeneralSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_GENERAL_ENABLED];
    BOOL isBlockSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_BLOCK_ENABLED];
    BOOL isPlaceHolderSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_PLACEHOLDER_ENABLED];
    
    // 根据单例返回的结果，对应的调用方法
    if(isGeneralSwitchOn)
    {
        if(isBlockSwitchOn)
        {
            if(isPlaceHolderSwitchOn)
            {
                // 有block和占位图片
                [self BlockDoneLoadWithURL:imageURL andPlaceHolderPic:img];
            }else
            {
                // 只有block
                [self BlockDoneLoadWithURL:imageURL];
            }
        }else
        {
            if(isPlaceHolderSwitchOn)
            {
                // 只有占位图片
                [self generalLoadWithURL:imageURL andPlaceHolderPic:img];
            }else
            {
                // 基本
                [self generalLoadWithURL:imageURL];
            }
        }
    }
}

// 基本的加载
- (void)generalLoadWithURL:(NSURL *)imgURL
{
    [self.imageView sd_setImageWithURL:imgURL];
    [self Manager:imgURL];
}

// 带block
- (void)BlockDoneLoadWithURL:(NSURL *)imgURL
{
    [self.imageView sd_setImageWithURL:imgURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        self.progressLabel.text = @"加载完成";
    }];
    [self Manager:imgURL];
}

// 带占位图片
- (void)generalLoadWithURL:(NSURL *)imgURL andPlaceHolderPic:(UIImage *)img
{
    [self.imageView sd_setImageWithURL:imgURL placeholderImage:img];
    [self Manager:imgURL];
}

// 既带block，也带占位图片
- (void)BlockDoneLoadWithURL:(NSURL *)imgURL andPlaceHolderPic:(UIImage *)img
{
    [self.imageView sd_setImageWithURL:imgURL placeholderImage:img completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        self.progressLabel.text = @"加载完成";
    }];
    [self Manager:imgURL];
}

// 下载中途的响应方法，可以获取进度
- (void)Manager:(NSURL *)imageURL
{
    // 覆盖方法，这个方法是下载imagePath的时候响应
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    [manager downloadImageWithURL:imageURL options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
//        NSLog(@"%@", [NSThread currentThread]);
//        NSLog(@"%f", receivedSize / (expectedSize * 1.0));
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.progressView.progress = receivedSize / (expectedSize * 1.0);
        }];
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        
        
        switch (cacheType) {
            case 0:
                NSLog(@"SDImageCacheTypeNone    ---  The image wasn't available the SDWebImage caches, but was downloaded from the web.");
                break;
            case 1:
                NSLog(@"SDImageCacheTypeDisk    ---  The image was obtained from the disk cache.");
                break;
            case 2:
                NSLog(@"SDImageCacheTypeMemory  ---  The image was obtained from the memory cache.");
                break;
                
            default:
                break;
        }
    
    }];
}

// 打开选项表
-(IBAction)showOptions:(id)sender {
    OptionsViewController *modal = [[OptionsViewController alloc] initWithNibName:@"OptionsViewController" bundle:[NSBundle mainBundle]];
    modal.transitioningDelegate = self;
    modal.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:modal animated:YES completion:nil];
}

- (IBAction)homeDirectoryPath:(id)sender {
    NSLog(@"%@", [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"com.hackemist.SDWebImageCache.default"]);
}

#pragma mark - Transitioning Delegate (Modal)
-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    _modalAnimationController.type = AnimationTypePresent;
    return _modalAnimationController;
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    _modalAnimationController.type = AnimationTypeDismiss;
    return _modalAnimationController;
}

/***************************************************************************
 
 //失败后重试
 SDWebImageRetryFailed = 1 << 0,
 
 //UI交互期间开始下载，导致延迟下载比如UIScrollView减速。
 SDWebImageLowPriority = 1 << 1,
 
 //只进行内存缓存
 SDWebImageCacheMemoryOnly = 1 << 2,
 
 //这个标志可以渐进式下载,显示的图像是逐步在下载
 SDWebImageProgressiveDownload = 1 << 3,
 
 //刷新缓存
 SDWebImageRefreshCached = 1 << 4,
 
 //后台下载
 SDWebImageContinueInBackground = 1 << 5,
 
 //NSMutableURLRequest.HTTPShouldHandleCookies = YES;
 
 SDWebImageHandleCookies = 1 << 6,
 
 //允许使用无效的SSL证书
 //SDWebImageAllowInvalidSSLCertificates = 1 << 7,
 
 //优先下载
 SDWebImageHighPriority = 1 << 8,
 
 //延迟占位符
 SDWebImageDelayPlaceholder = 1 << 9,
 
 //改变动画形象
 SDWebImageTransformAnimatedImage = 1 << 10,
 
 －－－－－－－－－－－－－－－－－－－－－－愚蠢的分割线啊！－－－－－－－－－－－－－－－－－－－－－－－－
 
 **
 * The image wasn't available the SDWebImage caches, but was downloaded from the web.
 *
 
 * SDImageCacheTypeNone,
 
 *
 * The image was obtained from the disk cache.
 *
 
 * SDImageCacheTypeDisk,
 
 *
 * The image was obtained from the memory cache.
 *
 
 * SDImageCacheTypeMemory
 
 *

 －－－－－－－－－－－－－－－－－－－－－－愚蠢的分割线啊！－－－－－－－－－－－－－－－－－－－－－－－－

 **
 * By default, when a URL fail to be downloaded, the URL is blacklisted so the library won't keep trying.
 * This flag disable this blacklisting.
 
SDWebImageRetryFailed = 1 << 0,

*
 * By default, image downloads are started during UI interactions, this flags disable this feature,
 * leading to delayed download on UIScrollView deceleration for instance.
 *
SDWebImageLowPriority = 1 << 1,

**
 * This flag disables on-disk caching
 *
SDWebImageCacheMemoryOnly = 1 << 2,

**
 * This flag enables progressive download, the image is displayed progressively during download as a browser would do.
 * By default, the image is only displayed once completely downloaded.
 *
SDWebImageProgressiveDownload = 1 << 3,

**
 * Even if the image is cached, respect the HTTP response cache control, and refresh the image from remote location if needed.
 * The disk caching will be handled by NSURLCache instead of SDWebImage leading to slight performance degradation.
 * This option helps deal with images changing behind the same request URL, e.g. Facebook graph api profile pics.
 * If a cached image is refreshed, the completion block is called once with the cached image and again with the final image.
 *
 * Use this flag only if you can't make your URLs static with embeded cache busting parameter.
 *
SDWebImageRefreshCached = 1 << 4,

**
 * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
 * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
 *
SDWebImageContinueInBackground = 1 << 5,

**
 * Handles cookies stored in NSHTTPCookieStore by setting
 * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
 *
SDWebImageHandleCookies = 1 << 6,

**
 * Enable to allow untrusted SSL ceriticates.
 * Useful for testing purposes. Use with caution in production.
 *
SDWebImageAllowInvalidSSLCertificates = 1 << 7,

**
 * By default, image are loaded in the order they were queued. This flag move them to
 * the front of the queue and is loaded immediately instead of waiting for the current queue to be loaded (which
 * could take a while).
 *
SDWebImageHighPriority = 1 << 8,

**
 * By default, placeholder images are loaded while the image is loading. This flag will delay the loading
 * of the placeholder image until after the image has finished loading.
 *
SDWebImageDelayPlaceholder = 1 << 9,

**
 * We usually don't call transformDownloadedImage delegate method on animated images,
 * as most transformation code would mangle it.
 * Use this flag to transform them anyway.
 *
SDWebImageTransformAnimatedImage = 1 << 10,

 ***************************************************************************/

@end
