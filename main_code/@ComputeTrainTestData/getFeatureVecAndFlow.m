function [comp_feat_vec calc_flows] = getFeatureVecAndFlow(obj, scene_id)

    % ensure that even if computation refresh is required, it is
    % only done once for each scene_id
    refresh = 0;
    if obj.compute_refresh
        if ~any(obj.feat_vec_flows_once_computed == scene_id)
            refresh = 1;
        end
    end

    scene_dir = obj.sceneId2SceneDir(scene_id);

    % compute/load the flow
    calc_flows = CalcFlows( scene_dir, obj.settings.cell_flows, obj.force_no_gt, refresh );

    % read in the images
    im1 = imread(fullfile(scene_dir, ComputeTrainTestData.IM1_PNG));
    im2 = imread(fullfile(scene_dir, ComputeTrainTestData.IM2_PNG));

    % get the extra info structure needed for computing some features
    extra_info = obj.extraFVInfoStruct( im1, im2, calc_flows );

    % compute/load all the features
    comp_feat_vec = ComputeFeatureVectors( scene_dir, obj.settings.cell_features, extra_info, obj.settings.ss_info_im1, obj.settings.ss_info_im2, refresh );
    
    
    % add to the set of IDs already computed
    obj.feat_vec_flows_once_computed = union(obj.feat_vec_flows_once_computed, scene_id);
end