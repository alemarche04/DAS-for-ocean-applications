function space_frequency_animation()

fx_animation = VideoWriter('space_grequency_animation.avi');
fx_animation.FrameRate = 5;
open(fx_animation);


% in loop
% genera frame
        frame = getframe(gcf); 
        writeVideo(outputVideo, frame);

close(fx_animation);

end