import { NativeEventEmitter, NativeModules, Platform } from 'react-native';

export type TrackingParams = Record<string, string | number>;

export interface InitializeOptions {
  appKey: string;
  channelId?: string;
  installParams?: TrackingParams;
  startupParams?: TrackingParams;
  caid?: string;
  caid2?: string;
  requestTrackingAuthorization?: boolean;
}

export interface AccountOptions {
  accountId: string;
  params?: TrackingParams;
}

export interface DeepLinkResult {
  url: string;
  params: TrackingParams;
}

interface MtrackingioNativeModule {
  preInit(appKey: string): Promise<void>;
  initialize(options: InitializeOptions): Promise<void>;
  setDebugLogging(enabled: boolean): Promise<void>;
  setASAEnabled(enabled: boolean): Promise<void>;
  register(options: AccountOptions): Promise<void>;
  login(options: AccountOptions): Promise<void>;
  setAttributionParameter(gdtClickId: string): Promise<void>;
  getInstallParams(): Promise<TrackingParams>;
  getStartupParams(): Promise<TrackingParams>;
  getInitialDeepLink(): Promise<DeepLinkResult | null>;
}

const CHANNEL_ID = '_default_';
const DEEP_LINK_EVENT = 'mtrackingio:deepLink';

const nativeModule = NativeModules.Mtrackingio as
  | MtrackingioNativeModule
  | undefined;

const nativeEmitter = nativeModule
  ? new NativeEventEmitter(NativeModules.Mtrackingio)
  : null;

function ensureNativeModule(): MtrackingioNativeModule {
  if (!nativeModule) {
    throw new Error("'react-native-mtrackingio' is not linked correctly.");
  }

  return nativeModule;
}

function assertAppKey(appKey: string) {
  if (!appKey.trim()) {
    throw new Error('appKey is required');
  }
}

function normalizeTrackingParams(
  params?: TrackingParams
): TrackingParams | undefined {
  if (!params) {
    return undefined;
  }

  return Object.fromEntries(
    Object.entries(params).filter(([, value]) => value !== undefined)
  ) as TrackingParams;
}

function normalizeInitializeOptions(
  options: InitializeOptions
): InitializeOptions {
  assertAppKey(options.appKey);

  return {
    ...options,
    appKey: options.appKey.trim(),
    channelId: options.channelId?.trim() || CHANNEL_ID,
    installParams: normalizeTrackingParams(options.installParams),
    startupParams: normalizeTrackingParams(options.startupParams),
  };
}

function normalizeAccountOptions(options: AccountOptions): AccountOptions {
  if (!options.accountId.trim()) {
    throw new Error('accountId is required');
  }

  return {
    accountId: options.accountId.trim(),
    params: normalizeTrackingParams(options.params),
  };
}

export function preInit(options: { appKey: string }): Promise<void> {
  assertAppKey(options.appKey);
  return ensureNativeModule().preInit(options.appKey.trim());
}

export function initialize(options: InitializeOptions): Promise<void> {
  return ensureNativeModule().initialize(normalizeInitializeOptions(options));
}

export function setDebugLogging(enabled: boolean): Promise<void> {
  return ensureNativeModule().setDebugLogging(enabled);
}

export function setASAEnabled(enabled: boolean): Promise<void> {
  return ensureNativeModule().setASAEnabled(enabled);
}

export function register(options: AccountOptions): Promise<void> {
  return ensureNativeModule().register(normalizeAccountOptions(options));
}

export function login(options: AccountOptions): Promise<void> {
  return ensureNativeModule().login(normalizeAccountOptions(options));
}

export function setAttributionParameter(options: {
  gdtClickId: string;
}): Promise<void> {
  if (!options.gdtClickId.trim()) {
    throw new Error('gdtClickId is required');
  }

  return ensureNativeModule().setAttributionParameter(options.gdtClickId.trim());
}

export function getInstallParams(): Promise<TrackingParams> {
  return ensureNativeModule().getInstallParams();
}

export function getStartupParams(): Promise<TrackingParams> {
  return ensureNativeModule().getStartupParams();
}

export function getInitialDeepLink(): Promise<DeepLinkResult | null> {
  return ensureNativeModule().getInitialDeepLink();
}

export function addDeepLinkListener(
  listener: (event: DeepLinkResult) => void
): { remove: () => void } {
  if (!nativeEmitter || Platform.OS === 'web') {
    return { remove() {} };
  }

  const subscription = nativeEmitter.addListener(DEEP_LINK_EVENT, (event) => {
    listener(event as DeepLinkResult);
  });
  return {
    remove() {
      subscription.remove();
    },
  };
}
