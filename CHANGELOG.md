## 1.0.1

* Initial release of the `safe_executor` package.
* Provides the `SafeExecutor.run` method for safely executing asynchronous functions.
* Includes a sealed `Result` class (`Success` and `Failure`) for robust and type-safe error handling.
* Built-in support for:
    * Automatic retries on failure.
    * Timeouts to limit execution time.
    * Custom error mapping to transform exceptions into clean error types.