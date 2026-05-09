package digigun.virt.virtualbox;

enum abstract MachineState(Int) from Int to Int {
    final Null = 0;
    final PoweredOff = 1;
    final Saved = 2;
    final Teleported = 3;
    final Aborted = 4;
    final AbortedSaved = 5;
    final Running = 6;
    final Paused = 7;
    final Stuck = 8;
    final Teleporting = 9;
    final LiveSnapshotting = 10;
    final Starting = 11;
    final Stopping = 12;
    final Saving = 13;
    final Restoring = 14;
    final TeleportingPausedVM = 15;
    final TeleportingIn = 16;
    final FaultTolerantSyncing = 17;
    final DeletingSnapshotOnline = 18;
    final DeletingSnapshotPaused = 19;
    final RestoringSnapshot = 20;
    final DeletingSnapshot = 21;
    final SettingUp = 22;
    final Snapshotting = 23;
    final OnlineSnapshotting = 24;
    final RestoringSnapshotPaused = 25;
    final RestoringSnapshotOnline = 26;
    final DeletingSnapshotLive = 27;
}
