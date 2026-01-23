function sg = DAS4Whale_Bou22_spectrogram()
	sg.sg_channel_position_km	= 42;
	sg.sg_nfft					= 4096;
	sg.sg_window_len			= 512;
	sg.sg_window				= hann(sg.sg_window_len, 'periodic');
	sg.sg_overlap_pct			= 0.89;
	sg.sg_time_lim				= [];
	sg.sg_frequency_lim			= [10 80];
	sg.sg_strain_lim			= [-25 0];
end