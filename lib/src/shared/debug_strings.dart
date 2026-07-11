import 'debug_constants.dart';

/// Central catalogue of user-facing display strings for DebugLens.
///
/// One flat, feature-prefixed namespace (e.g. [networkTitle], [logsEmpty]).
/// Copy that needs runtime values is exposed as a static method
/// (e.g. [settingsMaxItems]). Technical strings — map/JSON keys, route names,
/// log tags, ANSI codes, `MockSeed` data, and pure-composition interpolations
/// (`'$a $b'`) — are intentionally NOT centralised here.
class DebugStrings {
  DebugStrings._();

  // --- Common ---------------------------------------------------------------
  static const String commonClose = 'Close';
  static const String commonCancel = 'Cancel';

  // --- Dashboard ------------------------------------------------------------
  static const String dashboardTitle = '🔍 DebugLens';
  static const String dashboardNetwork = 'Network';
  static const String dashboardLogs = 'Logs';
  static const String dashboardNotifications = 'Notif / Deeplink';
  static const String dashboardNavigation = 'Navigation';
  static const String dashboardBloc = 'Bloc';
  static const String dashboardStorage = 'Storage';
  static const String dashboardDevice = 'Device & App';
  static const String dashboardFirebase = 'Firebase';
  static const String dashboardLocale = 'Locale';
  static const String dashboardSettings = 'Settings';
  static const String dashboardDeveloperAccess = 'Developer access';
  static const String dashboardPasswordHint = 'Enter password';
  static const String dashboardPasswordError = 'Incorrect password';
  static const String dashboardUnlock = 'Unlock';
  static const String roleDeveloper = 'DEVELOPER';
  static const String roleTester = 'TESTER';

  // --- Settings -------------------------------------------------------------
  static const String settingsTitle = 'Settings';
  static const String settingsCapture = 'Capture';
  static const String settingsCaptureNetwork = 'Network';
  static const String settingsCaptureLogs = 'Logs';
  static const String settingsCaptureNotifications = 'Notifications';
  static const String settingsCaptureNavigation = 'Navigation';
  static const String settingsCaptureStorage = 'Storage';
  static const String settingsCaptureCrashes = 'Crashes';
  static const String settingsCaptureAnalytics = 'Analytics';
  static const String settingsPrivacy = 'Privacy';
  static const String settingsRedactHeaders = 'Redact sensitive headers';
  static const String settingsRedactSubtitle =
      'Mask Authorization, cookies, tokens';
  static const String settingsBuffer = 'Buffer';
  static const String settingsData = 'Data';
  static const String settingsClearAll = 'Clear all data';
  static const String settingsClearedToast = 'All in-memory data cleared';
  static const String settingsAbout = 'About';
  static const String settingsAboutValue = 'DebugLens · UI scaffold · v0.0.1';
  static String settingsMaxItems(int n) => 'Max items per type: $n';

  // --- Device ---------------------------------------------------------------
  static const String deviceTitle = 'Device & App';

  // --- Common (shared across event feeds) -----------------------------------
  static const String commonSortNewest = 'Newest first (tap for oldest)';
  static const String commonSortOldest = 'Oldest first (tap for newest)';
  static const String commonFilterAll = 'All';
  static const String commonNoMatch = 'No events match the filter';
  static const String commonUnknown = 'unknown';
  static const String commonErrorHeader = 'ERROR';
  static const String commonStackHeader = 'STACK';
  static String commonCopyField(String label) => 'Copy $label';
  static String commonFieldCopied(String label) => '"$label" copied';

  // --- Notifications --------------------------------------------------------
  static const String notificationsTitle = 'Notifications / Deeplinks';
  static const String notificationsTabNotifications = 'Notifications';
  static const String notificationsTabDeeplinks = 'Deeplinks';
  static const String notificationsEmpty = 'No notifications';
  static const String notificationsNoTitle = '(no title)';

  // --- Deeplinks ------------------------------------------------------------
  static const String deeplinksEmpty = 'No deeplinks';
  static const String deeplinksScheme = 'scheme';
  static const String deeplinksHost = 'host';
  static const String deeplinksPath = 'path';
  static const String deeplinksNoQueryParams = 'no query params';

  // --- Bloc -----------------------------------------------------------------
  static const String blocTitle = 'Bloc';
  static const String blocClearTooltip = 'Clear bloc events';
  static const String blocClearedToast = 'Bloc events cleared';
  static const String blocFilterHint = 'Filter by bloc name';
  static const String blocEmpty = 'No bloc events yet';
  static const String blocSummaryCreated = 'created';
  static const String blocSummaryClosed = 'closed';
  static const String blocSummaryError = 'error';
  static String blocSummaryEvent(String? event) =>
      'event · ${event ?? DebugConstants.emptyValue}';
  static const String blocLabelBloc = 'bloc';
  static const String blocLabelAction = 'action';
  static const String blocLabelEvent = 'event';
  static const String blocLabelCurrent = 'current';
  static const String blocLabelNext = 'next';

  // --- Navigation -----------------------------------------------------------
  static const String navigationTitle = 'Navigation';
  static const String navigationClearTooltip = 'Clear navigation logs';
  static const String navigationClearedToast = 'Navigation logs cleared';
  static const String navigationTabEvents = 'Events';
  static const String navigationTabStack = 'Stack';
  static const String navigationEmpty = 'No navigation events';
  static const String navigationStackEmpty = 'Stack is empty';
  static const String navigationCurrent = 'current';
  static const String navigationLabelNavigator = 'navigator';
  static const String navigationFrom = 'from';
  static const String navigationTo = 'to';
  static const String navigationNoArguments = 'no arguments';
  static const String navigationArgumentsHeader = 'ARGUMENTS';
  static const String navigationCopyArguments = 'Copy arguments';
  static const String navigationArgumentsCopied = 'Arguments copied';
  static const String navigationSearchHint = 'Search route';
  static const String navigationHideInternal = 'Hide DebugLens routes';
  static const String navigationShowInternal = 'Show DebugLens routes';
  static const String navigationShareTooltip = 'Share navigation logs';
  static const String navigationShareSubject = 'DebugLens navigation logs';
  static const String navigationInternalLabel = 'debug_lens';

  // --- Locale ---------------------------------------------------------------
  static const String localeTitle = 'Locale';
  static const String localeSearchHint = 'Search keys or values';
  static const String localeEmpty = 'No locale entries';
  static const String localeNoMatches = 'No matches';
  static const String localeColumnKey = 'KEY';
  static const String localeColumnValue = 'VALUE';
  static const String localeKey = 'Key';
  static const String localeValue = 'Value';

  // --- Firebase -------------------------------------------------------------
  static const String firebaseTitle = 'Firebase';
  static const String firebaseEmpty = 'No Firebase services';
  static const String firebaseReload = 'Reload';
  static const String firebaseServiceEmpty = 'No data';
  static const String firebaseNone = 'none';
  static const String commonRetry = 'Retry';
  static String firebaseLoadFailed(Object? error) => 'Failed to load\n$error';

  // --- Common (continued) ---------------------------------------------------
  static const String commonCopy = 'Copy';
  static const String commonNoMatches = 'No matches';
  static String commonCopiedShare(String label) =>
      '$label copied — opening share…';

  // --- Storage --------------------------------------------------------------
  static const String storageTitle = 'Storage';
  static const String storageRefreshTooltip = 'Refresh current tab';
  static const String storageTabPrefs = 'SharedPrefs';
  static const String storageTabDatabase = 'Database';
  static const String storageSearchTables = 'Search tables';
  static const String storageNoTables = 'No tables';
  static const String storageNoMatchingTables = 'No matching tables';
  static const String storageNoColumns = 'No columns';
  static const String storageTableEmpty = 'Table is empty';
  static const String storageSearchDatabases = 'Search databases';
  static const String storageNoDatabases = 'No databases';
  static const String storageSearchKeys = 'Search keys';
  static const String storageNoPreferences = 'No preferences';
  static const String storageNoMatchingKeys = 'No matching keys';
  static const String storagePreference = 'Preference';
  static const String storageEncrypted = 'ENCRYPTED';
  static const String storageKeyTitle = 'Key';
  static const String storageValueTitle = 'Value';
  static String storageRefreshed(String which) => '$which refreshed';
  static String storageRowCount(int n) => '$n row${n == 1 ? '' : 's'}';
  static String storageTablesLoadFailed(Object? error) =>
      'Failed to read tables\n$error';
  static String storageTableLoadFailed(Object? error) =>
      'Failed to read table\n$error';

  // --- Logs -----------------------------------------------------------------
  static const String logsTitle = 'Logs';
  static const String logsShareTooltip = 'Share logs as file';
  static const String logsClearTooltip = 'Clear logs';
  static const String logsClearedToast = 'Logs cleared';
  static const String logsSearchHint = 'Search message / name';
  static const String logsEmpty = 'No logs';
  static const String logsDetailTitle = 'Log detail';
  static const String logsCopyFullTooltip = 'Copy full record';
  static const String logsCopiedToast = 'Log copied to clipboard';
  static const String logsConsoleBadge = 'C';
  static const String logsSummaryCard = 'Summary';
  static const String logsMessageCard = 'Message';
  static const String logsErrorCard = 'Error';
  static const String logsStackCard = 'Stack trace';
  static const String logsLabelLevel = 'Level';
  static const String logsLabelName = 'Name';
  static const String logsLabelSource = 'Source';
  static const String logsLabelTime = 'Time';
  static const String logsConsole = 'console';
  static const String logsLog = 'log';
  static String logsShareSubject(String stamp) => 'DebugLens logs ($stamp)';

  // --- Common (continued) ---------------------------------------------------
  static String commonCopied(String label) => '$label copied';

  // --- Network --------------------------------------------------------------
  static const String networkTitle = 'Network';
  static const String networkHistoryTooltip = 'API call history';
  static const String networkClearTooltip = 'Clear network log';
  static const String networkClearedToast = 'Network log cleared';
  static const String networkSearchHint = 'Search url / method';
  static const String networkEmpty = 'No requests captured';
  static const String networkHistoryTitle = 'History';
  static const String networkHistoryEmpty = 'No API calls this session';
  static const String networkHistorySortDesc =
      'Most called first (tap for least)';
  static const String networkHistorySortAsc =
      'Least called first (tap for most)';
  static const String networkStatusSuccess = 'Success';
  static const String networkStatusError = 'Error';
  static const String networkStatusPending = 'Pending';
  static const String networkPending = 'pending';
  static const String networkCopyCurl = 'Copy cURL';
  static const String networkCopyShareToast =
      'cURL + response copied — opening share…';
  static const String networkCall = 'call';
  static const String networkCalls = 'calls';
  static const String networkConnWifi = 'Wi-Fi';
  static const String networkConnMobile = 'Mobile data';
  static const String networkConnEthernet = 'Ethernet';
  static const String networkConnVpn = 'VPN';
  static const String networkConnBluetooth = 'Bluetooth';
  static const String networkConnOther = 'Other';
  static const String networkConnOffline = 'Offline';
  static const String networkConnChecking = 'Checking…';
  static const String networkTabOverview = 'Overview';
  static const String networkTabRequest = 'Request';
  static const String networkTabResponse = 'Response';
  static const String networkCurlLabel = 'cURL';
  static const String networkCopyShareRequest = 'Copy + share full request';
  static const String networkCopyShareCurl = 'Copy + share cURL';
  static const String networkNoRequestBody = 'No request body';
  static const String networkNoResponseBody = 'No response body';
  static const String networkRequestBodyLabel = 'Request body';
  static const String networkPrevMatch = 'Previous match';
  static const String networkNextMatch = 'Next match';
  static const String networkRequestHeaders = 'Request headers';
  static const String networkResponseHeaders = 'Response headers';
  static const String networkGeneral = 'General';
  static const String networkLabelUrl = 'URL';
  static const String networkLabelPath = 'Path';
  static const String networkLabelMethod = 'Method';
  static const String networkLabelStatus = 'Status';
  static const String networkLabelRequestTime = 'Request Time';
  static const String networkLabelResponseTime = 'Response Time';
  static const String networkLabelDuration = 'Duration';
  static const String networkLabelContentType = 'Content-Type';
  static const String networkLabelResponseType = 'Response-Type';
  static const String networkLabelReqSize = 'Req size';
  static const String networkLabelRespSize = 'Resp size';
  static const String networkQueryParams = 'Query parameters';
  static const String networkNone = 'none';
  static String networkOk(int n) => 'OK $n';
  static String networkErr(int n) => 'ERR $n';
  static String networkPend(int n) => 'PEND $n';
  static String networkSearchBody(String label) =>
      'Search ${label.toLowerCase()}';

  // --- Shared widgets -------------------------------------------------------
  static const String commonCopyButton = 'COPY';
  static const String commonClear = 'Clear';
  static const String commonBodyLabel = 'Body';
  static const String jsonObjectMode = 'Object';
  static const String jsonRawMode = 'JSON';
  static const String matrixAccessMode = 'ACCESS MODE';
}
