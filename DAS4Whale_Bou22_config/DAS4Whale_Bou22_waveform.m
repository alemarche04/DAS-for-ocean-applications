function wf = DAS4Whale_Bou22_waveform()
	wf.wf_channel_position_km	= 42;
	wf.wf_cpa_km				= 42.8;
	wf.wf_time_lim				= [];
	wf.wf_strain_lim			= [-1.3e-9 1.3e-9];
	wf.filename_audio			= fullfile(dataset_name, ['strain_waveform_' dataset_name  '.wav']);
end