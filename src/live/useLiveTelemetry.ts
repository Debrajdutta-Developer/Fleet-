import { useEffect, useMemo, useState } from 'react';
import { fetchLiveTelemetry, type LiveTelemetryReading } from './telemetryClient';

interface LiveTelemetryState {
  readings: LiveTelemetryReading[];
  loading: boolean;
  error: string | null;
  lastUpdatedAt: string | null;
}

export function useLiveTelemetry(pollMs = 5000): LiveTelemetryState & {
  byVehicleId: Map<string, LiveTelemetryReading>;
} {
  const [state, setState] = useState<LiveTelemetryState>({
    readings: [],
    loading: true,
    error: null,
    lastUpdatedAt: null,
  });

  useEffect(() => {
    let disposed = false;
    let timer: number | undefined;
    let controller: AbortController | null = null;

    const poll = async () => {
      controller?.abort();
      controller = new AbortController();

      try {
        const payload = await fetchLiveTelemetry(controller.signal);
        if (!disposed) {
          setState({
            readings: payload.vehicles,
            loading: false,
            error: null,
            lastUpdatedAt: payload.generatedAt,
          });
        }
      } catch (error) {
        if (!disposed && !(error instanceof DOMException && error.name === 'AbortError')) {
          setState((previous) => ({
            ...previous,
            loading: false,
            error: error instanceof Error ? error.message : 'Telemetry feed unavailable',
          }));
        }
      } finally {
        if (!disposed) timer = window.setTimeout(poll, pollMs);
      }
    };

    void poll();

    return () => {
      disposed = true;
      controller?.abort();
      if (timer !== undefined) window.clearTimeout(timer);
    };
  }, [pollMs]);

  const byVehicleId = useMemo(
    () => new Map(state.readings.map((reading) => [reading.vehicleId, reading])),
    [state.readings]
  );

  return { ...state, byVehicleId };
}
