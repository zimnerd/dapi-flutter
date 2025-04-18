  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(_controller);
    
    // Wrap autoLogin in Future.microtask to avoid Riverpod state modification during build
    Future.microtask(() => _autoLogin());
    
    // Listen for external filter changes
    _profileFiltersListener = ref.listen(
      profileFiltersProvider, 
      (previous, next) {
        if (previous != next) {
          _handleFilterUpdate();
        }
      }
    );
  }