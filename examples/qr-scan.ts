// Mobile example with React Native Vision Camera.
// The scanner should return an opaque, short-lived token; never treat raw
// Employee ID or personal data in a QR payload as an authenticated session.
import { useEffect, useState } from 'react';
import { Camera, useCameraDevice, useCodeScanner } from 'react-native-vision-camera';

export function usePpeQrScanner(onToken: (token: string) => Promise<void>) {
  const device = useCameraDevice('back');
  const [permission, setPermission] = useState(false);
  const [locked, setLocked] = useState(false);

  useEffect(() => {
    Camera.requestCameraPermission().then((status) => setPermission(status === 'granted'));
  }, []);

  const codeScanner = useCodeScanner({
    codeTypes: ['qr'],
    onCodeScanned: async (codes) => {
      const token = codes[0]?.value;
      if (!token || locked) return;

      setLocked(true); // debounce duplicate camera callbacks
      try {
        await onToken(token);
      } finally {
        setLocked(false);
      }
    },
  });

  return {
    camera: permission && device ? <Camera device={device} isActive={!locked} codeScanner={codeScanner} /> : null,
    permission,
  };
}

// Example API handler for scanning a requisition QR at the warehouse.
export async function resolveRequisitionQr(token: string, accessToken: string) {
  const response = await fetch('/api/v1/inventory/scan/resolve', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      'Idempotency-Key': crypto.randomUUID(),
    },
    body: JSON.stringify({ token }),
  });

  if (!response.ok) throw new Error(`QR resolve failed: ${response.status}`);
  return response.json() as Promise<{ requisitionId: string; status: string; requestNo: string }>;
}
