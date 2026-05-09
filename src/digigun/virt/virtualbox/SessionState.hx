package digigun.virt.virtualbox;

enum abstract SessionState(Int) from Int to Int {
    final Null = 0;
    final Unlocked = 1;
    final Locked = 2;
    final Spawning = 3;
    final Unlocking = 4;
}
