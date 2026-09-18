@override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280, // Fix magasság, hogy ne okozzon overflow hibát a képernyőn!
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F19),
              border: Border.all(color: const Color(0xFF00FFFF), width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: _isVideoInitialized
                ? VideoPlayer(_controller)
                : const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00FFFF),
                    ),
                  ),
          ),
        ),
      ),
    );
  }