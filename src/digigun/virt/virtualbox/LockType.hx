package digigun.virt.virtualbox;

enum abstract LockType(Int) from Int to Int {
    final Null = 0;
    final Shared = 1;
    final Write = 2;
    final VM = 3;
}
