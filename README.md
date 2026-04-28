# react-native-mtrackingio

React Native TrackingIO SDK 封装。

## 安装

```sh
npm install react-native-mtrackingio
```

iOS 如已集成 CocoaPods，请再执行：

```sh
cd ios && pod install
```

## 当前结构

仓库保持最小源码直出结构：

- `src/index.ts`：源码入口，直接作为 npm 包入口发布
- `android/`：Android Kotlin 原生桥接与本地 jar
- `ios/`：iOS 原生桥接与 `TrackingIOSDK.xcframework`
- `Mtrackingio.podspec`：iOS pod 配置

这个包不再发布 `lib/` 构建产物，而是由 React Native 宿主工程直接处理包内源码。

## 用法

```ts
import {
  preInit,
  initialize,
  setDebugLogging,
  register,
  login,
  getInstallParams,
  getStartupParams,
  getInitialDeepLink,
  addDeepLinkListener,
} from 'react-native-mtrackingio';

await preInit({ appKey: 'YOUR_APP_KEY' });
await setDebugLogging(true);

await initialize({
  appKey: 'YOUR_APP_KEY',
  channelId: '_default_',
  installParams: { plan: 'basic' },
  startupParams: { source: 'app' },
});

await register({ accountId: 'user_001' });
await login({ accountId: 'user_001' });

const installParams = await getInstallParams();
const startupParams = await getStartupParams();
const initialDeepLink = await getInitialDeepLink();

const subscription = addDeepLinkListener((event) => {
  console.log('deep link', event.url, event.params);
});

subscription.remove();
```

## API

### `preInit({ appKey })`

预初始化 TrackingIO SDK。

### `initialize(options)`

初始化 TrackingIO SDK。

支持字段：

- `appKey`
- `channelId`
- `installParams`
- `startupParams`
- `caid`
- `caid2`
- `requestTrackingAuthorization`

### `setDebugLogging(enabled)`

打开或关闭调试日志。

### `setASAEnabled(enabled)`

iOS 专用，控制 ASA 开关，建议在 `initialize()` 前调用。

### `register({ accountId, params? })`

上报注册事件，需要在 `initialize()` 后调用。

### `login({ accountId, params? })`

上报登录事件，需要在 `initialize()` 后调用。

### `setAttributionParameter({ gdtClickId })`

Android 专用，设置归因补充参数，建议在 `initialize()` 前调用。

### `getInstallParams()` / `getStartupParams()`

返回当前桥接层缓存的初始化参数，不是 SDK 的实时查询结果。

### `getInitialDeepLink()`

返回当前进程内首次收到的 SDK deep link 回调缓存；如果回调尚未到达，则返回 `null`。

### `addDeepLinkListener(listener)`

监听运行时 deep link 回调。

## 平台说明

### Android

仓库内已包含：

- `android/libs/tracking1.9.12.jar`
- `android/libs/bcprov-jdk16-139.jar`

并在 `android/build.gradle` 中接入华为 / 荣耀 OAID 依赖。

Android 当前实现说明：

- `preInit` / `initialize` / `setDebugLogging` / `register` / `login` / `setAttributionParameter` 已接真实 SDK。
- `getInstallParams` / `getStartupParams` 返回桥接层缓存值。
- `getInitialDeepLink` 与 `addDeepLinkListener` 基于 SDK deep link 回调实现。

### iOS

仓库内已包含：

- `ios/TrackingIOSDK.xcframework`

iOS 当前实现说明：

- `preInit` / `initialize` / `setDebugLogging` / `setASAEnabled` / `register` / `login` 已接真实 SDK。
- `getInstallParams` / `getStartupParams` 返回桥接层缓存值。
- `getInitialDeepLink` 与 `addDeepLinkListener` 基于 deferred deep link delegate 实现。
- `setAttributionParameter` 当前仅支持 Android。
- `requestTrackingAuthorization` 字段当前不会自动触发 ATT 授权请求。

## 状态说明

当前这次整理的重点是：

- 改成源码直出发布模型
- 删除 `lib/` 构建产物依赖
- 删除 bob / TypeScript 发布构建链
- 接入 Android / iOS 原生 TrackingIO SDK
- 保留最小 React Native 原生模块结构

当前包不再单独发布构建后的类型声明文件。

## License

MIT
