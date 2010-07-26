function [ extra_info ] = extraFVInfoStruct( obj, im1, im2, calc_flows )
% Extra information structure headed for ComputeFeatureVectors

    % compute the scale space for all the candidate algorithms
    extra_info.flow_scalespace.no_scales = obj.settings.uv_ss_info(1);
    extra_info.flow_scalespace.scale = obj.settings.uv_ss_info(2);
    extra_info.flow_scalespace.ss = cell(1, extra_info.flow_scalespace.no_scales);
    
    % iterate over  all candidate algos
    for flow_idx = 1:size(calc_flows.uv_flows,4)
        flow_scalespace_x = ComputeFeatureVectors.computeScaleSpace( calc_flows.uv_flows(:,:,1,flow_idx), ...
            extra_info.flow_scalespace.no_scales, extra_info.flow_scalespace.scale );
        flow_scalespace_y = ComputeFeatureVectors.computeScaleSpace( calc_flows.uv_flows(:,:,2,flow_idx), ...
            extra_info.flow_scalespace.no_scales, extra_info.flow_scalespace.scale );
        
        % iterate over all scales
        for scale_idx = 1:extra_info.flow_scalespace.no_scales
            temp = cat(3, flow_scalespace_x{scale_idx}, flow_scalespace_y{scale_idx});
            extra_info.flow_scalespace.ss{scale_idx} = cat(4, extra_info.flow_scalespace.ss{scale_idx}, temp);
        end
    end
    
    % store the CalcFlow object containing all the candidate flow algorithms
    extra_info.calc_flows = calc_flows;
end