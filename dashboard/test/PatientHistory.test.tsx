import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { PatientHistory } from '@/components/PatientHistory';
import { json, mockFetch } from './helpers';

describe('PatientHistory', () => {
  it('shows the patient, their CHW and each visit with what was recorded', async () => {
    const fetch = mockFetch(() =>
      json({
        patient: { id: 'p1', shortId: 'P0412', name: 'Uwase Marie', village: 'Nyamata', sex: 'F', ageEstimate: 32, birthDate: null, archived: false },
        chw: { id: 'c1', name: 'Claudine M.', phone: '+250780000101' },
        visits: [
          { id: 'v1', type: 'maternal', recordedAt: '2026-11-10T08:00:00Z', receivedAt: null, isUrgent: true, isPartial: false, dangerSigns: ['Heavy bleeding'], temperature: 38.9, condition: 'Needs attention', symptoms: 'Headache', notes: 'Referred', followUpOn: null },
        ],
      }),
    );
    render(<PatientHistory id="p1" />);
