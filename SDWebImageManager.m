/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey  *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
 
#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"
#import "SDWebImageDownloader.h"
#import "SDImageCache.h"
 
typedef NS_OPTIONS(NSUInteger, SDWebImageOptions) {
    /**
     * By default, when a URL fail to be downloaded, the URL is blacklisted so the library won't keep trying.
     * This flag disable this blacklisting.
     */
    /**
     *默认情况下,如果一个url在下载的时候失败了,那么这个url会被加入黑名单并且library不会尝试再次下载,这个flag会阻止library把失败的url加入黑名单(简单来说如果选择了这个flag,那么即使某个url下载失败了,sdwebimage还是会尝试再次下载他.)
     */
    SDWebImageRetryFailed = 1 << 0,
 
    /**
     * By default, image downloads are started during UI interactions, this flags disable this feature,
     * leading to delayed download on UIScrollView deceleration for instance.
     */
 
    /**
     *默认情况下,图片会在交互发生的时候下载(例如你滑动tableview的时候),这个flag会禁止这个特性,导致的结果就是在scrollview减速的时候
     *才会开始下载(也就是你滑动的时候scrollview不下载,你手从屏幕上移走,scrollview开始减速的时候才会开始下载图片)
     */
    SDWebImageLowPriority = 1 << 1,
 
    /**
     * This flag disables on-disk caching
     */
    /*
     *这个flag禁止磁盘缓存,只有内存缓存
     */
    SDWebImageCacheMemoryOnly = 1 << 2,
 
    /**
     * This flag enables progressive download, the image is displayed progressively during download as a browser would do.
     * By default, the image is only displayed once completely downloaded.
     */
    /*
     *这个flag会在图片下载的时候就显示(就像你用浏览器浏览网页的时候那种图片下载,一截一截的显示(待确认))
     *
     */
    SDWebImageProgressiveDownload = 1 << 3,
 
    /**
     * Even if the image is cached, respect the HTTP response cache control, and refresh the image from remote location if needed.
     * The disk caching will be handled by NSURLCache instead of SDWebImage leading to slight performance degradation.
     * This option helps deal with images changing behind the same request URL, e.g. Facebook graph api profile pics.
     * If a cached image is refreshed, the completion block is called once with the cached image and again with the final image.
     *
     * Use this flag only if you can't make your URLs static with embeded cache busting parameter.
     */
    /*
     *这个选项的意思看的不是很懂,大意是即使一个图片缓存了,还是会重新请求.并且缓存侧略依据NSURLCache而不是SDWebImage.
     *
     */
    SDWebImageRefreshCached = 1 << 4,
 
    /**
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    /*
     *启动后台下载,加入你进入一个页面,有一张图片正在下载这时候你让app进入后台,图片还是会继续下载(这个估计要开backgroundfetch才有用)
     */
    SDWebImageContinueInBackground = 1 << 5,
 
    /**
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    /*
     *可以控制存在NSHTTPCookieStore的cookies.(我没用过,等用过的人过来解释一下)
     */
    SDWebImageHandleCookies = 1 << 6,
 
    /**
     * Enable to allow untrusted SSL ceriticates.
     * Useful for testing purposes. Use with caution in production.
     */
    /*
     *允许不安全的SSL证书,在正式环境中慎用
     */
    SDWebImageAllowInvalidSSLCertificates = 1 << 7,
 
    /**
     * By default, image are loaded in the order they were queued. This flag move them to
     * the front of the queue and is loaded immediately instead of waiting for the current queue to be loaded (which 
     * could take a while).
     */
    /*
     *默认情况下,image在装载的时候是按照他们在队列中的顺序装载的(就是先进先出).这个flag会把他们移动到队列的前端,并且立刻装载
     *而不是等到当前队列装载的时候再装载.
     */
    SDWebImageHighPriority = 1 << 8,
 
    /**
     * By default, placeholder images are loaded while the image is loading. This flag will delay the loading
     * of the placeholder image until after the image has finished loading.
     */
    /*
     *默认情况下,占位图会在图片下载的时候显示.这个flag开启会延迟占位图显示的时间,等到图片下载完成之后才会显示占位图.(等图片显示完了我干嘛还显示占位图?或许是我理解错了?)
     */
    SDWebImageDelayPlaceholder = 1 << 9,
 
    /**
     * We usually don't call transformDownloadedImage delegate method on animated images,
     * as most transformation code would mangle it.
     * Use this flag to transform them anyway.
     */
    /* 
     *是否transform图片(没用过,还要再看,但是据我估计,是否是图片有可能方向不对需要调整方向,例如采用iPhone拍摄的照片如果不纠正方向,那么图片是向左旋转90度的.可能很多人不知道iPhone的摄像头并不是竖直的,而是向左偏了90度.具体请google.)
     */
    SDWebImageTransformAnimatedImage = 1 << 10,
};
 
typedef void(^SDWebImageCompletionBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL);
 
typedef void(^SDWebImageCompletionWithFinishedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL);
 
typedef NSString *(^SDWebImageCacheKeyFilterBlock)(NSURL *url);
 
 
@class SDWebImageManager;
 
@protocol SDWebImageManagerDelegate @optional
 
/**
 * Controls which image should be downloaded when the image is not found in the cache.
 *
 * @param imageManager The current `SDWebImageManager`
 * @param imageURL     The url of the image to be downloaded
 *
 * @return Return NO to prevent the downloading of the image on cache misses. If not implemented, YES is implied.
 */
/*
 *主要作用是当缓存里没有发现某张图片的缓存时,是否选择下载这张图片(默认是yes),可以选择no,那么sdwebimage在缓存中没有找到这张图片的时候不会选择下载
 */
- (BOOL)imageManager:(SDWebImageManager *)imageManager shouldDownloadImageForURL:(NSURL *)imageURL;
 
/**
 * Allows to transform the image immediately after it has been downloaded and just before to cache it on disk and memory.
 * NOTE: This method is called from a global queue in order to not to block the main thread.
 *
 * @param imageManager The current `SDWebImageManager`
 * @param image        The image to transform
 * @param imageURL     The url of the image to transform
 *
 * @return The transformed image object.
 */
/**
 *在图片下载完成并且还没有加入磁盘缓存或者内存缓存的时候就transform这个图片.这个方法是在异步线程执行的,防止阻塞主线程.
 *至于为什么在异步执行很简单,对一张图片纠正方向(也就是transform)是很耗资源的,一张2M大小的图片纠正方向你可以用instrument测试一下耗时.
 *很恐怖
 */
- (UIImage *)imageManager:(SDWebImageManager *)imageManager transformDownloadedImage:(UIImage *)image withURL:(NSURL *)imageURL;
 
@end
 
/**
 * The SDWebImageManager is the class behind the UIImageView+WebCache category and likes.
 * It ties the asynchronous downloader (SDWebImageDownloader) with the image cache store (SDImageCache).
 * You can use this class directly to benefit from web image downloading with caching in another context than
 * a UIView.
 *
 * Here is a simple example of how to use SDWebImageManager:
 *
 * @code
 
SDWebImageManager *manager = [SDWebImageManager sharedManager];
[manager downloadImageWithURL:imageURL
                      options:0
                     progress:nil
                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                        if (image) {
                            // do something with image
                        }
                    }];
 
 * @endcode
 */
/*
 *这一段是阐述SDWebImageManager是干嘛的.其实UIImageView+WebCache这个category背后执行操作的就是这个SDWebImageManager.他会绑定一个下载器也就是SDWebImageDownloader和一个缓存SDImageCache.后面的大意应该是讲你可以直接使用一个其他上下文环境的SDWebImageManager,而不是仅仅限于一个UIView.
 */
@interface SDWebImageManager : NSObject
 
@property (weak, nonatomic) id  delegate;
/**
 
 *如同上文所说,一个SDWebImageManager会绑定一个imageCache和一个下载器.
 */
@property (strong, nonatomic, readonly) SDImageCache *imageCache;
@property (strong, nonatomic, readonly) SDWebImageDownloader *imageDownloader;
 
/**
 * The cache filter is a block used each time SDWebImageManager need to convert an URL into a cache key. This can
 * be used to remove dynamic part of an image URL.
 *
 * The following example sets a filter in the application delegate that will remove any query-string from the
 * URL before to use it as a cache key:
 *
 * @code
 
[[SDWebImageManager sharedManager] setCacheKeyFilter:^(NSURL *url) {
    url = [[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path];
    return [url absoluteString];
}];
 
 * @endcode
 */
/*
 * 这个cacheKeyFilter是干嘛的呢?很简单.1他是一个block.2.这个block的作用就是生成一个image的key.因为sdwebimage的缓存原理你可以当成是一个字典,每一个字典的value就是一张image,那么这个value对应的key是什么呢?就是cacheKeyFilter根据某个规则对这个图片的url做一些操作生成的.上面的示例就显示了怎么利用这个block把image的url重新组合生成一个key.以后当sdwebimage检测到你
 */
@property (nonatomic, copy) SDWebImageCacheKeyFilterBlock cacheKeyFilter;
 
/**
 * Returns global SDWebImageManager instance.
 *
 * @return SDWebImageManager shared instance
 */
/*
 *这个不用我解释了吧,生成一个SDWebImagemanager的单例.
 */
+ (SDWebImageManager *)sharedManager;
 
/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 * 从给定的URL中下载一个之前没有被缓存的Image.
 *
 * @param url            The URL to the image
 * @param options        A mask to specify options to use for this request
 * @param progressBlock  A block called while image is downloading
 * @param completedBlock A block called when operation has been completed.
 *
 *   This parameter is required.
 * 
 *   This block has no return value and takes the requested UIImage as first parameter.
 *   In case of error the image parameter is nil and the second parameter may contain an NSError.
 *
 *   The third parameter is an `SDImageCacheType` enum indicating if the image was retrived from the local cache
 *   or from the memory cache or from the network.
 *
 *   The last parameter is set to NO when the SDWebImageProgressiveDownload option is used and the image is 
 *   downloading. This block is thus called repetidly with a partial image. When image is fully downloaded, the
 *   block is called a last time with the full image and the last parameter set to YES.
 *
 * @return Returns an NSObject conforming to SDWebImageOperation. Should be an instance of SDWebImageDownloaderOperation
 */
 
/*
 * 这个方法主要就是SDWebImage下载图片的方法了.  
 * 第一个参数是必须要的,就是image的url
 * 第二个参数就是我们上面的Options,你可以定制化各种各样的操作.详情参上. 
 * 第三个参数是一个回调block,用于图片在下载过程中的回调.(英文注释应该是有问题的.)
 * 第四个参数是一个下载完成的回调.会在图片下载完成后回调.
 * 返回值是一个NSObject类,并且这个NSObject类是conforming一个协议这个协议叫做SDWebImageOperation,这个协议很简单,就是一个cancel掉operation的协议.
 */
- (id )downloadImageWithURL:(NSURL *)url
                                         options:(SDWebImageOptions)options
                                        progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                       completed:(SDWebImageCompletionWithFinishedBlock)completedBlock;
 
/**
 * Saves image to cache for given URL
 *
 * @param image The image to cache
 * @param url   The URL to the image
 *
 */
/*
 * 将图片存入cache的方法,类似于字典的setValue: forKey:
 */
- (void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url;
 
/**
 * Cancel all current opreations
 */
/*
 *取消掉当前所有的下载图片的operation
 */
- (void)cancelAll;
 
/**
 * Check one or more operations running
 */
/*
 * check一下是否有一个或者多个operation正在执行(简单来说就是check是否有图片在下载)
 */
- (BOOL)isRunning;
 
/**
 *  Check if image has already been cached
 *
 *  @param url image url
 *
 *  @return if the image was already cached
 */
/*
 * 通过一个image的url是否已经存在,如果存在返回yes,否则返回no
 */
- (BOOL)cachedImageExistsForURL:(NSURL *)url;
 
/**
 *  Check if image has already been cached on disk only
 *
 *  @param url image url
 *
 *  @return if the image was already cached (disk only)
 */
/*
 * 检测一个image是否已经被缓存到磁盘(是否存且仅存在disk里).
 */
- (BOOL)diskImageExistsForURL:(NSURL *)url;
 
/**
 *  Async check if image has already been cached
 *
 *  @param url              image url
 *  @param completionBlock  the block to be executed when the check is finished
 *  
 *  @note the completion block is always executed on the main queue
 */
/*
 * 如果检测到图片已经被缓存,那么执行回调block.这个block会永远执行在主线程.也就是你可以在这个回调block里更新ui.
 */
- (void)cachedImageExistsForURL:(NSURL *)url
                     completion:(SDWebImageCheckCacheCompletionBlock)completionBlock;
 
/**
 *  Async check if image has already been cached on disk only
 *
 *  @param url              image url
 *  @param completionBlock  the block to be executed when the check is finished
 *
 *  @note the completion block is always executed on the main queue
 */
/*
 * 如果检测到图片已经被缓存在磁盘(存且仅存在disk),那么执行回调block.这个block会永远执行在主线程.也就是你可以在这个回调block里更新ui.
 */
- (void)diskImageExistsForURL:(NSURL *)url
                   completion:(SDWebImageCheckCacheCompletionBlock)completionBlock;
 
 
/**
 *Return the cache key for a given URL
 */
/*
 * 通过image的url返回image存在缓存里的key.有人会问了,为什么不直接把图片的url当做image的key来使用呢?而是非要对url做一些处理才能当做key.我的解释是,我也不太清楚.可能为了防止重复吧.
 */
- (NSString *)cacheKeyForURL:(NSURL *)url;
 
@end
 
 
#pragma mark - Deprecated
 
typedef void(^SDWebImageCompletedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType) __deprecated_msg("Block type deprecated. Use `SDWebImageCompletionBlock`");
typedef void(^SDWebImageCompletedWithFinishedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) __deprecated_msg("Block type deprecated. Use `SDWebImageCompletionWithFinishedBlock`");
 
// 已被废弃
@interface SDWebImageManager (Deprecated)
 
/**
 *  Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 *  @deprecated This method has been deprecated. Use `downloadImageWithURL:options:progress:completed:`
 */
- (id )downloadWithURL:(NSURL *)url
                                    options:(SDWebImageOptions)options
                                   progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                  completed:(SDWebImageCompletedWithFinishedBlock)completedBlock __deprecated_msg("Method deprecated. Use `downloadImageWithURL:options:progress:completed:`");
 
@end





                                  /*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey  *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
 
#import "SDWebImageManager.h"
#import // 内部类.
@interface SDWebImageCombinedOperation : NSObject @property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@property (copy, nonatomic) SDWebImageNoParamsBlock cancelBlock;
@property (strong, nonatomic) NSOperation *cacheOperation;
 
@end
 
@interface SDWebImageManager ()
 
@property (strong, nonatomic, readwrite) SDImageCache *imageCache;
@property (strong, nonatomic, readwrite) SDWebImageDownloader *imageDownloader;
@property (strong, nonatomic) NSMutableSet *failedURLs;
@property (strong, nonatomic) NSMutableArray *runningOperations;
 
@end
 
@implementation SDWebImageManager
 
// 利用disptach_once 特性生成一个单例,用烂了的方法.不赘述.
+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}
 
// 初始化方法.
// 1.获得一个SDImageCache的单例.2.获取一个SDWebImageDownloader的单例.3.新建一个MutableSet来存储下载失败的url.
// 4.新建一个用来存储下载operation的可变数组.
// 为什么不用MutableArray储存下载失败的URL?
// 因为NSSet类有一个特性,就是Hash.实际上NSSet是一个哈希表,哈希表比数组优秀的地方是什么呢?就是查找速度快.查找同样一个元素,哈希表只需要通过key
// 即可取到,而数组至少需要遍历依次.因为SDWebImage里有关失败URL的业务需求是,一个失败的URL只需要储存一次.这样的话Set自然比Array更合适.
- (id)init {
    if ((self = [super init])) {
        _imageCache = [self createCache];
        _imageDownloader = [SDWebImageDownloader sharedDownloader];
        _failedURLs = [NSMutableSet new];
        _runningOperations = [NSMutableArray new];
    }
    return self;
}
 
// 获取一个cache的单例
- (SDImageCache *)createCache {
    return [SDImageCache sharedImageCache];
}
 
// 利用Image的URL生成一个缓存时需要的key.
// 这里有两种情况,第一种是如果检测到cacheKeyFilter不为空时,利用cacheKeyFilter来处理URL生成一个key.
// 如果为空,那么直接返回URL的string内容,当做key.
- (NSString *)cacheKeyForURL:(NSURL *)url {
    if (self.cacheKeyFilter) {
        return self.cacheKeyFilter(url);
    }
    else {
        return [url absoluteString];
    }
}
 
// 检测一张图片是否已被缓存.
// 首先检测内存缓存是否存在这张图片,如果已有,直接返回yes.
// 如果内存缓存里没有这张图片,那么调用diskImageExistsWithKey这个方法去硬盘缓存里找
- (BOOL)cachedImageExistsForURL:(NSURL *)url {
    NSString *key = [self cacheKeyForURL:url];
    if ([self.imageCache imageFromMemoryCacheForKey:key] != nil) return YES;
    return [self.imageCache diskImageExistsWithKey:key];
}
 
// 检测硬盘里是否缓存了图片
- (BOOL)diskImageExistsForURL:(NSURL *)url {
    NSString *key = [self cacheKeyForURL:url];
    return [self.imageCache diskImageExistsWithKey:key];
}
 
// 首先生成一个用来cache 住Image的key(利用key的url生成)
// 然后检测内存缓存里是否已经有这张图片
// 如果已经被缓存,那么再主线程里回调block
// 如果没有检测到,那么调用diskImageExistsWithKey,这个方法会在异步线程里,将图片存到硬盘,当然在存图之前也会检测是否已在硬盘缓存图片.
 
- (void)cachedImageExistsForURL:(NSURL *)url
                     completion:(SDWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
 
    BOOL isInMemoryCache = ([self.imageCache imageFromMemoryCacheForKey:key] != nil);
 
    if (isInMemoryCache) {
        // making sure we call the completion block on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(YES);
            }
        });
        return;
    }
 
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // the completion block of checkDiskCacheForImageWithKey:completion: is always called on the main queue, no need to further dispatch
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}
 
//将图片存入硬盘
 
- (void)diskImageExistsForURL:(NSURL *)url
                   completion:(SDWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
 
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // the completion block of checkDiskCacheForImageWithKey:completion: is always called on the main queue, no need to further dispatch
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}
 
// 通过url建立一个operation用来下载图片.
- (id )downloadImageWithURL:(NSURL *)url
                                         options:(SDWebImageOptions)options
                                        progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                       completed:(SDWebImageCompletionWithFinishedBlock)completedBlock {
    // Invoking this method without a completedBlock is pointless
    NSAssert(completedBlock != nil, @"If you mean to prefetch the image, use -[SDWebImagePrefetcher prefetchURLs] instead");
 
    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
 
    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }
 
    __block SDWebImageCombinedOperation *operation = [SDWebImageCombinedOperation new];
    __weak SDWebImageCombinedOperation *weakOperation = operation;
 
    BOOL isFailedUrl = NO;
    // 创建一个互斥锁防止现在有别的线程修改failedURLs.
    // 判断这个url是否是fail过的.如果url failed过的那么isFailedUrl就是true
    @synchronized (self.failedURLs) {
        isFailedUrl = [self.failedURLs containsObject:url];
    }
    // 如果url不存在那么直接返回一个block,如果url存在.那么继续进行判断.
    // options与SDWebImageRetryFailed这个option进行按位与操作.判断用户的options里是否有retry这个option.
    // 如果用户的options里没有retry这个选项并且isFaileUrl 是true.那么就回调一个error的block.
    if (!url || (!(options & SDWebImageRetryFailed) && isFailedUrl)) {
        dispatch_main_sync_safe(^{
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil];
            completedBlock(nil, error, SDImageCacheTypeNone, YES, url);
        });
        return operation;
    }
 
    // 创建一个互斥锁防止现在有别的线程修改runningOperations.
    @synchronized (self.runningOperations) {
        [self.runningOperations addObject:operation];
    }
    NSString *key = [self cacheKeyForURL:url];
 
    // cacheOperation应该是一个用来下载图片并且缓存的operation
    operation.cacheOperation = [self.imageCache queryDiskCacheForKey:key done:^(UIImage *image, SDImageCacheType cacheType) {
        // 判断operation这时候有没有执行cancel操作,如果cancel掉了就把这个operation从我们的operation数组里remove掉然后return
        if (operation.isCancelled) {
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
 
            return;
        }
 
        if ((!image || options & SDWebImageRefreshCached) && (![self.delegate respondsToSelector:@selector(imageManager:shouldDownloadImageForURL:)] || [self.delegate imageManager:self shouldDownloadImageForURL:url])) {
            if (image && options & SDWebImageRefreshCached) {
                dispatch_main_sync_safe(^{
                    // If image was found in the cache bug SDWebImageRefreshCached is provided, notify about the cached image
                    // AND try to re-download it in order to let a chance to NSURLCache to refresh it from server.
                    completedBlock(image, nil, cacheType, YES, url);
                });
            }
 
            // download if no image or requested to refresh anyway, and download allowed by delegate
            // 下面都是判断我们的options里包含哪些SDWebImageOptions,然后给我们的downloaderOptions相应的添加对应的SDWebImageDownloaderOptions. downloaderOptions |= SDWebImageDownloaderLowPriority这种表达式的意思等同于
            // downloaderOptions = downloaderOptions | SDWebImageDownloaderLowPriority
            SDWebImageDownloaderOptions downloaderOptions = 0;
            if (options & SDWebImageLowPriority) downloaderOptions |= SDWebImageDownloaderLowPriority;
            if (options & SDWebImageProgressiveDownload) downloaderOptions |= SDWebImageDownloaderProgressiveDownload;
            if (options & SDWebImageRefreshCached) downloaderOptions |= SDWebImageDownloaderUseNSURLCache;
            if (options & SDWebImageContinueInBackground) downloaderOptions |= SDWebImageDownloaderContinueInBackground;
            if (options & SDWebImageHandleCookies) downloaderOptions |= SDWebImageDownloaderHandleCookies;
            if (options & SDWebImageAllowInvalidSSLCertificates) downloaderOptions |= SDWebImageDownloaderAllowInvalidSSLCertificates;
            if (options & SDWebImageHighPriority) downloaderOptions |= SDWebImageDownloaderHighPriority;
            if (image && options & SDWebImageRefreshCached) {
                // force progressive off if image already cached but forced refreshing
                downloaderOptions &= ~SDWebImageDownloaderProgressiveDownload;
                // ignore image read from NSURLCache if image if cached but force refreshing
                downloaderOptions |= SDWebImageDownloaderIgnoreCachedResponse;
            }
 
            // 调用imageDownloader去下载image并且返回执行这个request的download的operation
            id  subOperation = [self.imageDownloader downloadImageWithURL:url options:downloaderOptions progress:progressBlock completed:^(UIImage *downloadedImage, NSData *data, NSError *error, BOOL finished) {
                if (weakOperation.isCancelled) {
                    // Do nothing if the operation was cancelled
                    // See #699 for more details
                    // if we would call the completedBlock, there could be a race condition between this block and another completedBlock for the same object, so if this one is called second, we will overwrite the new data
                }
                else if (error) {
                    dispatch_main_sync_safe(^{
                        if (!weakOperation.isCancelled) {
                            completedBlock(nil, error, SDImageCacheTypeNone, finished, url);
                        }
                    });
 
                    if (error.code != NSURLErrorNotConnectedToInternet && error.code != NSURLErrorCancelled && error.code != NSURLErrorTimedOut) {
                        @synchronized (self.failedURLs) {
                            [self.failedURLs addObject:url];
                        }
                    }
                }
                else {
                    if ((options & SDWebImageRetryFailed)) {
                        @synchronized (self.failedURLs) {
                            [self.failedURLs removeObject:url];
                        }
                    }
 
                    BOOL cacheOnDisk = !(options & SDWebImageCacheMemoryOnly);
 
                    if (options & SDWebImageRefreshCached && image && !downloadedImage) {
                        // Image refresh hit the NSURLCache cache, do not call the completion block
                    }
                    else if (downloadedImage && (!downloadedImage.images || (options & SDWebImageTransformAnimatedImage)) && [self.delegate respondsToSelector:@selector(imageManager:transformDownloadedImage:withURL:)]) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            UIImage *transformedImage = [self.delegate imageManager:self transformDownloadedImage:downloadedImage withURL:url];
 
                            if (transformedImage && finished) {
                                BOOL imageWasTransformed = ![transformedImage isEqual:downloadedImage];
                                [self.imageCache storeImage:transformedImage recalculateFromImage:imageWasTransformed imageData:data forKey:key toDisk:cacheOnDisk];
                            }
 
                            dispatch_main_sync_safe(^{
                                if (!weakOperation.isCancelled) {
                                    completedBlock(transformedImage, nil, SDImageCacheTypeNone, finished, url);
                                }
                            });
                        });
                    }
                    else {
                        if (downloadedImage && finished) {
                            [self.imageCache storeImage:downloadedImage recalculateFromImage:NO imageData:data forKey:key toDisk:cacheOnDisk];
                        }
 
                        dispatch_main_sync_safe(^{
                            if (!weakOperation.isCancelled) {
                                completedBlock(downloadedImage, nil, SDImageCacheTypeNone, finished, url);
                            }
                        });
                    }
                }
 
                if (finished) {
                    @synchronized (self.runningOperations) {
                        [self.runningOperations removeObject:operation];
                    }
                }
            }];
            operation.cancelBlock = ^{
                [subOperation cancel];
 
                @synchronized (self.runningOperations) {
                    [self.runningOperations removeObject:weakOperation];
                }
            };
        }
        else if (image) {
            dispatch_main_sync_safe(^{
                if (!weakOperation.isCancelled) {
                    completedBlock(image, nil, cacheType, YES, url);
                }
            });
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
        }
        else {
            // Image not in cache and download disallowed by delegate
            dispatch_main_sync_safe(^{
                if (!weakOperation.isCancelled) {
                    completedBlock(nil, nil, SDImageCacheTypeNone, YES, url);
                }
            });
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
        }
    }];
 
    return operation;
}
 
- (void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url {
    if (image && url) {
        NSString *key = [self cacheKeyForURL:url];
        [self.imageCache storeImage:image forKey:key toDisk:YES];
    }
}
 
// cancel掉所有正在执行的operation
- (void)cancelAll {
    @synchronized (self.runningOperations) {
        NSArray *copiedOperations = [self.runningOperations copy];
        [copiedOperations makeObjectsPerformSelector:@selector(cancel)];
        [self.runningOperations removeObjectsInArray:copiedOperations];
    }
}
 
// 判断是否有正在运行的operation
 
- (BOOL)isRunning {
    return self.runningOperations.count > 0;
}
 
@end
 
 
@implementation SDWebImageCombinedOperation
 
- (void)setCancelBlock:(SDWebImageNoParamsBlock)cancelBlock {
    // check if the operation is already cancelled, then we just call the cancelBlock
    if (self.isCancelled) {
        if (cancelBlock) {
            cancelBlock();
        }
        _cancelBlock = nil; // don't forget to nil the cancelBlock, otherwise we will get crashes
    } else {
        _cancelBlock = [cancelBlock copy];
    }
}
 
- (void)cancel {
    self.cancelled = YES;
    if (self.cacheOperation) {
        [self.cacheOperation cancel];
        self.cacheOperation = nil;
    }
    if (self.cancelBlock) {
        self.cancelBlock();
 
        // TODO: this is a temporary fix to #809.
        // Until we can figure the exact cause of the crash, going with the ivar instead of the setter
//        self.cancelBlock = nil;
        _cancelBlock = nil;
    }
}
 
@end
 
 
@implementation SDWebImageManager (Deprecated)
 
// deprecated method, uses the non deprecated method
// adapter for the completion block
- (id )downloadWithURL:(NSURL *)url options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedWithFinishedBlock)completedBlock {
    return [self downloadImageWithURL:url
                              options:options
                             progress:progressBlock
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                if (completedBlock) {
                                    completedBlock(image, error, cacheType, finished);
                                }
                            }];
}
 
@end





/*
下面来简单的解释一下OC里枚举的两种类型.

NS_ENUM和NS_OPTIONS

本质上是一样的都是枚举.

我举个例子.

typedef NS_ENUM(NSInteger, UIViewAnimationTransition) {
    UIViewAnimationTransitionNone,
    UIViewAnimationTransitionFlipFromLeft,
    UIViewAnimationTransitionFlipFromRight,
    UIViewAnimationTransitionCurlUp,
    UIViewAnimationTransitionCurlDown,
};


typedef NS_OPTIONS(NSUInteger, UIViewAutoresizing) {
    UIViewAutoresizingNone                 = 0,
    UIViewAutoresizingFlexibleLeftMargin   = 1 << 0,
    UIViewAutoresizingFlexibleWidth        = 1 << 1,
    UIViewAutoresizingFlexibleRightMargin  = 1 << 2,
    UIViewAutoresizingFlexibleTopMargin    = 1 << 3,
    UIViewAutoresizingFlexibleHeight       = 1 << 4,
    UIViewAutoresizingFlexibleBottomMargin = 1 << 5
};
应该可以看出一些苗头.

NS_ENUM这种声明出来的东西大部分是单选. NS_OPTIONS声明出来的大部分是多选.

像UIViewAnimationTransition这种在用的时候肯定是只能选一种效果,你要么从左翻到右,要么从右翻到左,你做动画的时候总不能同一时刻让他同时从左到右,又从右到左翻,对吧.

而UIViewAutosizing就不一样了.我要是让子view的宽高和父View一样,那么autoviewsizing的选项肯定是类似于这种.UIViewAutoresizingFlexibleWidth  | UIViewAutoresizingFlexibleHeight

没错吧,意思就是两个options的我都得选才行.

那么如果有个场景让我判断当前的view的Autoresizing有哪几个.我怎么判断呢?

很简单.用按位与操作就行了.

假设 autoResizings = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;

我们判断autoResizings里是否有UIViewAutoresizingFlexibleLeftMargin的时候只需要if(autoResizings & UIViewAutoresizingFlexibleLeftMargin)是否为true就可以了.

用二进制表示的话(这里不用care NSUInteger到底是几位的.就表示这么个意思)


UIViewAutoresizingFlexibleLeftMargin = 00000001
UIViewAutoresizingFlexibleWidth = 00000010
UIViewAutoresizingFlexibleRightMargin = 00000100
所以根据上面的表达式,我们的autoResizings = 00000111.

那么执行按位与操作是这样的.


 00000111
&00000001   
结果就是00000001,为true.表示含有这个选项.


*/