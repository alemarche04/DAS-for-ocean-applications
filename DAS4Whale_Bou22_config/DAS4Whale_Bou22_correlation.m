function xcorr = DAS4Whale_Bou22_correlation()
	xcorr.corr_channel_position_km	= 42;
	xcorr.corr_offset_m				= 300;
	xcorr.corr_time_lag				= 0.2;
	xcorr.corr_time_interval		= [47 50];
	xcorr.corr_cpa_km				= 42.8;
	xcorr.filename_xcorr_table		= fullfile(dataset_name, ['cross_corr_stats_' dataset_name  '.csv']);
end