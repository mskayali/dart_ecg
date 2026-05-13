import neurokit2 as nk
import numpy as np
import json
import os

def generate_golden():
    duration = 10
    sampling_rate = 250
    
    # Generate an ECGSYN signal with some noise
    ecg = nk.ecg_simulate(duration=duration, sampling_rate=sampling_rate, method="ecgsyn", random_state=42)
    
    # Process the signal using default neurokit method
    signals, info = nk.ecg_process(ecg, sampling_rate=sampling_rate)
    
    output = {
        "raw": ecg.tolist(),
        "sampling_rate": sampling_rate,
        "clean": signals["ECG_Clean"].tolist(),
        "rpeaks_signal": signals["ECG_R_Peaks"].tolist(),
        "rpeaks": info["ECG_R_Peaks"].tolist(),
        "rate": signals["ECG_Rate"].tolist(),
        "quality": signals["ECG_Quality"].tolist(),
        "p_peaks": signals["ECG_P_Peaks"].tolist(),
        "q_peaks": signals["ECG_Q_Peaks"].tolist(),
        "s_peaks": signals["ECG_S_Peaks"].tolist(),
        "t_peaks": signals["ECG_T_Peaks"].tolist(),
        "phase_atrial": signals["ECG_Phase_Atrial"].tolist(),
        "phase_ventricular": signals["ECG_Phase_Ventricular"].tolist(),
        "cwt_p_peaks": [int(x) if not np.isnan(x) else float('nan') for x in nk.ecg_delineate(ecg, info["ECG_R_Peaks"], sampling_rate=sampling_rate, method="cwt")[1]["ECG_P_Peaks"]],
        "cwt_p_onsets": [int(x) if not np.isnan(x) else float('nan') for x in nk.ecg_delineate(ecg, info["ECG_R_Peaks"], sampling_rate=sampling_rate, method="cwt")[1]["ECG_P_Onsets"]],
        "cwt_t_peaks": [int(x) if not np.isnan(x) else float('nan') for x in nk.ecg_delineate(ecg, info["ECG_R_Peaks"], sampling_rate=sampling_rate, method="cwt")[1]["ECG_T_Peaks"]],
        "cwt_r_onsets": [int(x) if not np.isnan(x) else float('nan') for x in nk.ecg_delineate(ecg, info["ECG_R_Peaks"], sampling_rate=sampling_rate, method="cwt")[1]["ECG_R_Onsets"]],
        "edr_vangent": nk.ecg_rsp(signals["ECG_Rate"], sampling_rate=sampling_rate, method="vangent2019").tolist(),
        "edr_charlton": nk.ecg_rsp(signals["ECG_Rate"], sampling_rate=sampling_rate, method="charlton2016").tolist(),
        "edr_sarkar": nk.ecg_rsp(signals["ECG_Rate"], sampling_rate=sampling_rate, method="sarkar2015").tolist(),
        "edr_soni": nk.ecg_rsp(signals["ECG_Rate"], sampling_rate=sampling_rate, method="soni2019").tolist(),
    }
    
    # Replace NaN with null for JSON compatibility
    def clean_nan(arr):
        return [None if np.isnan(x) else x for x in arr]
        
    for k, v in output.items():
        if isinstance(v, list) and len(v) > 0 and isinstance(v[0], float):
            output[k] = clean_nan(v)

    os.makedirs("test/golden", exist_ok=True)
    with open("test/golden/ecg_process_golden.json", "w") as f:
        json.dump(output, f)
        
    print("Successfully generated golden reference data at test/golden/ecg_process_golden.json")

if __name__ == "__main__":
    generate_golden()
