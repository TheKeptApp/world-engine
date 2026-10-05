# Device performance runs

- `walk-10min/metrics.csv`: 10-minute walk loop on iPhone 14 Pro (iOS 26.4.2), with no Instruments attached. One row per second: fps, average and worst frame time, memory footprint and thermal state. Run with `NO_TRACE=1 scripts/walk_test.sh walk-10min`.
- `gpu-attribution.md`: short GPU-time samples with features switched off. These were traced at the induced minimum GPU state, so they're worst case.
