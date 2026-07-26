import 'package:debug_lens/debug_lens.dart';

/// Short alias for the DebugLens logger, so app code reads `log.i(...)`.
///
/// Everything logged through it lands on the Logs screen; whether it also
/// reaches the terminal is `printToConsole`, which `main` sets. An app that
/// already owns a logger keeps printing from that one and sets it `false`, so
/// DebugLens displays the record without printing it twice.
DebugLensLogger get log => DebugLensLogger.instance;
