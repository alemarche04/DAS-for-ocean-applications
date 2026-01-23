function fx = DAS4Whale_Bou22_fx()
	fx.fx_nfft				= 4096;
	fx.fx_time_interval		= [44 67];
	fx.fx_time_window		= 1.5;
	fx.fx_frequency_lim		= [5 75];
	fx.fx_strain_lim		= [-25 -5];
	fx.filename_animation	= fullfile(dataset_name, ['fx_animation_' dataset_name  '.avi']);
end