function visualize(k, x, stats, A, b, u0, v0, M, N)
	
	%% Reporting the results
	fprintf('Iterations: %d \n', k);

	%% Plotting the results
	MN = M*N; MN2 = 2*MN; MN3 = 3*MN;
	
	u = reshape(x(1:MN) + u0, M, N);
	v = reshape(x(MN+1:MN2) + v0, M, N);
	
	if size(x,1) > MN2
		e = reshape(x(MN2+1:MN3), M, N); 
	else
		e = reshape(A*x + b, M, N);
	end
	
	figure(1); 
	subplot(1, 2, 1); flowshow(cat(3, u, v));
	subplot(1, 2, 2); imagesc(abs(e), [0,min(max(max(abs(e))), 1)]); colormap jet; axis image; axis off;
	% 	
	% figure(2);
	% axis([0, size(stats.energy,2) min(stats.energy) max(stats.energy)]);
	% plot(1:k, stats.energy(1:k));
	% 
	drawnow;
	pause(0.01);