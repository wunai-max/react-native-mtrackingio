//
//  Tracking.h
//  ReYun_Tracking
//
//  Created by jesse on 2018/1/19.
//  Copyright © 2018年 yun. All rights reserved.
//
#define REYUN_TRACKING_VERSION @"2.0.2"
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

//deeplink callback 代理
@protocol DeferredDeeplinkCalllback <NSObject>
@required
- (void)onDeferredDeeplinkCalllback:(NSDictionary *)params;
@end

//激活归因回调代理
@protocol OnAttributionCallbackProtocol <NSObject>
@required
- (void)OnAttribution:(nullable NSString *)result status:(NSUInteger)httpStatus;
@end


@interface Tracking : NSObject

//开启打印日志(在initWithAppKey:withChannelId:前调用)
//正式上线包请关掉
+(void) setPrintLog :(BOOL)print;
//是否开启ASA归因查询，主动调用传入true开启，默认关闭(在initWithAppKey:withChannelId:前调用)
+(void) setASAEnable :(BOOL)enable;

+(void)preInit:(NSString *)appKey;
/// 开启数据统计
/// @param appKey 热云TrackingIO apppkey TrackingIO后台获取  必填
/// @param channelId 热云TrackingIO channelId  固定值@"_default_"
/// @param caid  客户自行传入参数  没有caid需求可为空 传入 nil
/// @param caid2  客户自行传入参数  没有caid2需求可为空 传入 nil
/// @param installParams 自定义install参数
/// @param startupParams 自定义startup参数
+ (void)initWithAppKey:(NSString *)appKey withChannelId:(NSString *)channelId withCAID:(nullable NSString *)caid
 withCAID2:(nullable NSString *)caid2  withInstallParams:(nullable NSDictionary *)installParams withStartupParams:(nullable NSDictionary *)startupParams;
//注册成功后调用
+ (void)setRegisterWithAccountID:(NSString *)account withParams:(nullable NSDictionary *)customParams;
//登陆成功后调用
+ (void)setLoginWithAccountID:(NSString *)account withParams:(nullable NSDictionary *)customParams;
//生成订单
+(void)setDD:(NSString *)ryTID hbType:(NSString*)hbType hbAmount:(float)hbAmount withParams:(nullable NSDictionary *)customParams;
// 支付完成，付费分析,记录玩家充值的金额（人民币单位是元）
+(void)setRyzf:(NSString *)ryTID ryzfType:(NSString*)ryzfType hbType:(NSString*)hbType hbAmount:(float)hbAmount withParams:(nullable NSDictionary *)customParams;
//广告展示时调用 playSuccess 参数调用广告填充成功时传1  不成功时传2
+(void)onAdShow:(NSString *)adPlatform adId:(NSString *)adId isSuccess:(int)playSuccess withParams:(nullable NSDictionary *)customParams;
//广告点击时调用
+(void)onAdClick:(NSString *)adPlatform adId:(NSString *)adId withParams:(nullable NSDictionary *)customParams;
//页面时长监测
+(void)trackViewName:(NSString *)pageID duration:(long)duration withParams:(nullable NSDictionary *)customParams;
//APP使用时长监测
+(void)setTrackAppDuration:(long)duration withParams:(nullable NSDictionary *)customParams;
//自定义事件
+(void)setEvent:(NSString *)eventName param:(nullable NSDictionary *)customParams;
//获取设备信息
+(NSString*)getDeviceId;

@end

@interface Tracking(DeepLink)
//延迟深度链接回调代理设置
+(void)setDeferredDeeplinkCalllbackDelegate:(id<DeferredDeeplinkCalllback>) delegate ;
@end

@interface Tracking(Attribution)
//激活归因回调代理设置
+(void)setAttributionCalllbackDelegate:(id<OnAttributionCallbackProtocol>) delegate ;
@end


NS_ASSUME_NONNULL_END
