#define __NR_read				0LL
#define __NR_write				1LL
#define __NR_open				2LL
#define __NR_close				3LL
#define __NR_stat				4LL
#define __NR_fstat				5LL
#define __NR_lstat				6LL
#define __NR_poll				7LL
#define __NR_lseek				8LL
#define __NR_mmap				9LL
#define __NR_mprotect			10LL
#define __NR_munmap				11LL
#define __NR_brk				12LL
#define __NR_rt_sigaction		13LL
#define __NR_rt_sigprocmask		14LL
#define __NR_rt_sigreturn		15LL
#define __NR_ioctl				16LL
#define __NR_pread64			17LL
#define __NR_pwrite64			18LL
#define __NR_readv				19LL
#define __NR_writev				20LL
#define __NR_access				21LL
#define __NR_pipe				22LL
#define __NR_select				23LL
#define __NR_sched_yield		24LL
#define __NR_mremap				25LL
#define __NR_msync				26LL
#define __NR_mincore			27LL
#define __NR_madvise			28LL
#define __NR_shmget				29LL
#define __NR_shmat				30LL
#define __NR_shmctl				31LL
#define __NR_dup				32LL
#define __NR_dup2				33LL
#define __NR_pause				34LL
#define __NR_nanosleep			35LL
#define __NR_getitimer			36LL
#define __NR_alarm				37LL
#define __NR_setitimer			38LL
#define __NR_getpid				39LL
#define __NR_sendfile			40LL
#define __NR_socket				41LL
#define __NR_connect			42LL
#define __NR_accept				43LL
#define __NR_sendto				44LL
#define __NR_recvfrom			45LL
#define __NR_sendmsg			46LL
#define __NR_recvmsg			47LL
#define __NR_shutdown			48LL
#define __NR_bind				49LL
#define __NR_listen				50LL
#define __NR_getsockname		51LL
#define __NR_getpeername		52LL
#define __NR_socketpair			53LL
#define __NR_setsockopt			54LL
#define __NR_getsockopt			55LL
#define __NR_clone				56LL
#define __NR_fork				57LL
#define __NR_vfork				58LL
#define __NR_execve				59LL
#define __NR_exit				60LL
#define __NR_wait4				61LL
#define __NR_kill				62LL
#define __NR_uname				63LL
#define __NR_semget				64LL
#define __NR_semop				65LL
#define __NR_semctl				66LL
#define __NR_shmdt				67LL
#define __NR_msgget				68LL
#define __NR_msgsnd				69LL
#define __NR_msgrcv				70LL
#define __NR_msgctl				71LL
#define __NR_fcntl				72LL
#define __NR_flock				73LL
#define __NR_fsync				74LL
#define __NR_fdatasync			75LL
#define __NR_truncate			76LL
#define __NR_ftruncate			77LL
#define __NR_getdents			78LL
#define __NR_getcwd				79LL
#define __NR_chdir				80LL
#define __NR_fchdir				81LL
#define __NR_rename				82LL
#define __NR_mkdir				83LL
#define __NR_rmdir				84LL
#define __NR_creat				85LL
#define __NR_link				86LL
#define __NR_unlink				87LL
#define __NR_symlink			88LL
#define __NR_readlink			89LL
#define __NR_chmod				90LL
#define __NR_fchmod				91LL
#define __NR_chown				92LL
#define __NR_fchown				93LL
#define __NR_lchown				94LL
#define __NR_umask				95LL
#define __NR_gettimeofday		96LL
#define __NR_getrlimit			97LL
#define __NR_getrusage			98LL
#define __NR_sysinfo			99LL
#define __NR_times				100LL
#define __NR_ptrace				101LL
#define __NR_getuid				102LL
#define __NR_syslog				103LL
#define __NR_getgid				104LL
#define __NR_setuid				105LL
#define __NR_setgid				106LL
#define __NR_geteuid			107LL
#define __NR_getegid			108LL
#define __NR_setpgid			109LL
#define __NR_getppid			110LL
#define __NR_getpgrp			111LL
#define __NR_setsid				112LL
#define __NR_setreuid			113LL
#define __NR_setregid			114LL
#define __NR_getgroups			115LL
#define __NR_setgroups			116LL
#define __NR_setresuid			117LL
#define __NR_getresuid			118LL
#define __NR_setresgid			119LL
#define __NR_getresgid			120LL
#define __NR_getpgid			121LL
#define __NR_setfsuid			122LL
#define __NR_setfsgid			123LL
#define __NR_getsid				124LL
#define __NR_capget				125LL
#define __NR_capset				126LL
#define __NR_rt_sigpending		127LL
#define __NR_rt_sigtimedwait	128LL
#define __NR_rt_sigqueueinfo	129LL
#define __NR_rt_sigsuspend		130LL
#define __NR_sigaltstack		131LL
#define __NR_utime				132LL
#define __NR_mknod				133LL
#define __NR_uselib				134LL
#define __NR_personality		135LL
#define __NR_ustat				136LL
#define __NR_statfs				137LL
#define __NR_fstatfs			138LL
#define __NR_sysfs				139LL
#define __NR_getpriority			140LL
#define __NR_setpriority			141LL
#define __NR_sched_setparam			142LL
#define __NR_sched_getparam			143LL
#define __NR_sched_setscheduler		144LL
#define __NR_sched_getscheduler		145LL
#define __NR_sched_get_priority_max	146LL
#define __NR_sched_get_priority_min	147LL
#define __NR_sched_rr_get_interval	148LL
#define __NR_mlock					149LL
#define __NR_munlock				150LL
#define __NR_mlockall				151LL
#define __NR_munlockall				152LL
#define __NR_vhangup				153LL
#define __NR_modify_ldt				154LL
#define __NR_pivot_root				155LL
#define __NR__sysctl				156LL
#define __NR_prctl					157LL
#define __NR_arch_prctl				158LL
#define __NR_adjtimex				159LL
#define __NR_setrlimit				160LL
#define __NR_chroot					161LL
#define __NR_sync					162LL
#define __NR_acct					163LL
#define __NR_settimeofday			164LL
#define __NR_mount					165LL
#define __NR_umount2				166LL
#define __NR_swapon					167LL
#define __NR_swapoff				168LL
#define __NR_reboot					169LL
#define __NR_sethostname			170LL
#define __NR_setdomainname			171LL
#define __NR_iopl					172LL
#define __NR_ioperm					173LL
#define __NR_create_module			174LL
#define __NR_init_module			175LL
#define __NR_delete_module			176LL
#define __NR_get_kernel_syms		177LL
#define __NR_query_module			178LL
#define __NR_quotactl				179LL
#define __NR_nfsservctl				180LL
#define __NR_getpmsg				181LL
#define __NR_putpmsg				182LL
#define __NR_afs_syscall			183LL
#define __NR_tuxcall				184LL
#define __NR_security				185LL
#define __NR_gettid					186LL
#define __NR_readahead				187LL
#define __NR_setxattr				188LL
#define __NR_lsetxattr				189LL
#define __NR_fsetxattr				190LL
#define __NR_getxattr				191LL
#define __NR_lgetxattr				192LL
#define __NR_fgetxattr				193LL
#define __NR_listxattr				194LL
#define __NR_llistxattr				195LL
#define __NR_flistxattr				196LL
#define __NR_removexattr			197LL
#define __NR_lremovexattr			198LL
#define __NR_fremovexattr			199LL
#define __NR_tkill					200LL
#define __NR_time					201LL
#define __NR_futex					202LL
#define __NR_sched_setaffinity		203LL
#define __NR_sched_getaffinity		204LL
#define __NR_set_thread_area		205LL
#define __NR_io_setup				206LL
#define __NR_io_destroy				207LL
#define __NR_io_getevents			208LL
#define __NR_io_submit				209LL
#define __NR_io_cancel				210LL
#define __NR_get_thread_area		211LL
#define __NR_lookup_dcookie			212LL
#define __NR_epoll_create			213LL
#define __NR_epoll_ctl_old			214LL
#define __NR_epoll_wait_old			215LL
#define __NR_remap_file_pages		216LL
#define __NR_getdents64				217LL
#define __NR_set_tid_address		218LL
#define __NR_restart_syscall		219LL
#define __NR_semtimedop				220LL
#define __NR_fadvise64				221LL
#define __NR_timer_create			222LL
#define __NR_timer_settime			223LL
#define __NR_timer_gettime			224LL
#define __NR_timer_getoverrun		225LL
#define __NR_timer_delete			226LL
#define __NR_clock_settime			227LL
#define __NR_clock_gettime			228LL
#define __NR_clock_getres			229LL
#define __NR_clock_nanosleep		230LL
#define __NR_exit_group				231LL
#define __NR_epoll_wait				232LL
#define __NR_epoll_ctl				233LL
#define __NR_tgkill					234LL
#define __NR_utimes					235LL
#define __NR_vserver				236LL
#define __NR_mbind					237LL
#define __NR_set_mempolicy			238LL
#define __NR_get_mempolicy			239LL
#define __NR_mq_open				240LL
#define __NR_mq_unlink				241LL
#define __NR_mq_timedsend			242LL
#define __NR_mq_timedreceive		243LL
#define __NR_mq_notify				244LL
#define __NR_mq_getsetattr			245LL
#define __NR_kexec_load				246LL
#define __NR_waitid					247LL
#define __NR_add_key				248LL
#define __NR_request_key			249LL
#define __NR_keyctl					250LL
#define __NR_ioprio_set				251LL
#define __NR_ioprio_get				252LL
#define __NR_inotify_init			253LL
#define __NR_inotify_add_watch		254LL
#define __NR_inotify_rm_watch		255LL
#define __NR_migrate_pages			256LL
#define __NR_openat					257LL
#define __NR_mkdirat				258LL
#define __NR_mknodat				259LL
#define __NR_fchownat				260LL
#define __NR_futimesat				261LL
#define __NR_newfstatat				262LL
#define __NR_unlinkat				263LL
#define __NR_renameat				264LL
#define __NR_linkat					265LL
#define __NR_symlinkat				266LL
#define __NR_readlinkat				267LL
#define __NR_fchmodat				268LL
#define __NR_faccessat				269LL
#define __NR_pselect6				270LL
#define __NR_ppoll					271LL
#define __NR_unshare				272LL
#define __NR_set_robust_list		273LL
#define __NR_get_robust_list		274LL
#define __NR_splice					275LL
#define __NR_tee					276LL
#define __NR_sync_file_range		277LL
#define __NR_vmsplice				278LL
#define __NR_move_pages				279LL
#define __NR_utimensat				280LL
#define __NR_epoll_pwait			281LL
#define __NR_signalfd				282LL
#define __NR_timerfd_create			283LL
#define __NR_eventfd				284LL
#define __NR_fallocate				285LL
#define __NR_timerfd_settime		286LL
#define __NR_timerfd_gettime		287LL
#define __NR_accept4				288LL
#define __NR_signalfd4				289LL
#define __NR_eventfd2				290LL
#define __NR_epoll_create1			291LL
#define __NR_dup3					292LL
#define __NR_pipe2					293LL
#define __NR_inotify_init1			294LL
#define __NR_preadv					295LL
#define __NR_pwritev				296LL
#define __NR_rt_tgsigqueueinfo		297LL
#define __NR_perf_event_open		298LL
#define __NR_recvmmsg				299LL
#define __NR_fanotify_init			300LL
#define __NR_fanotify_mark			301LL
#define __NR_prlimit64				302LL
#define __NR_name_to_handle_at			303LL
#define __NR_open_by_handle_at			304LL
#define __NR_clock_adjtime			305LL
#define __NR_syncfs				306LL
#define __NR_sendmmsg				307LL
#define __NR_setns				308LL
#define __NR_getcpu				309LL
#define __NR_process_vm_readv			310LL
#define __NR_process_vm_writev			311LL

static __inline long long __syscall0(long long n)
{
	unsigned long long ret;
	__asm__ __volatile__ ("syscall" : "=a"(ret) : "a"(n) : "rcx", "r11", "memory");
	return ret;
}

static __inline long long __syscall1(long long n, long long a1)
{
	unsigned long long ret;
	__asm__ __volatile__ ("syscall" : "=a"(ret) : "a"(n), "D"(a1) : "rcx", "r11", "memory");
	return ret;
}

static __inline long long __syscall2(long long n, long long a1, long long a2)
{
	unsigned long long ret;
	__asm__ __volatile__ ("syscall" : "=a"(ret) : "a"(n), "D"(a1), "S"(a2)
						  : "rcx", "r11", "memory");
	return ret;
}

static __inline long long __syscall3(long long n, long long a1, long long a2, long long a3)
{
	unsigned long long ret;
	__asm__ __volatile__ ("syscall" : "=a"(ret) : "a"(n), "D"(a1), "S"(a2),
						  "d"(a3) : "rcx", "r11", "memory");
	return ret;
}

static __inline long long __syscall4(long long n, long long a1, long long a2, long long a3, long long a4)
{
	unsigned long long ret;
	register long long r10 __asm__("r10") = a4;
	__asm__ __volatile__ ("syscall" : "=a"(ret) : "a"(n), "D"(a1), "S"(a2),
						  "d"(a3), "r"(r10): "rcx", "r11", "memory");
	return ret;
}

static __inline long long __syscall5(long long n, long long a1, long long a2, long long a3, long long a4, long long a5)
{
	unsigned long long ret;
	register long long r10 __asm__("r10") = a4;
	register long long r8 __asm__("r8") = a5;
	__asm__ __volatile__ ("syscall" : "=a"(ret) : "a"(n), "D"(a1), "S"(a2),
						  "d"(a3), "r"(r10), "r"(r8) : "rcx", "r11", "memory");
	return ret;
}

static __inline long long __syscall6(long long n, long long a1, long long a2, long long a3, long long a4, long long a5, long long a6)
{
	unsigned long long ret;
	register long long r10 __asm__("r10") = a4;
	register long long r8 __asm__("r8") = a5;
	register long long r9 __asm__("r9") = a6;
	__asm__ __volatile__ ("syscall" : "=a"(ret) : "a"(n), "D"(a1), "S"(a2),
						  "d"(a3), "r"(r10), "r"(r8), "r"(r9) : "rcx", "r11", "memory");
	return ret;
}
