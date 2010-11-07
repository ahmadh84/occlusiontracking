function [ varargout ] = trainingSequencesUtils( varargin )
% evaluate function according to the number of inputs and outputs
    if nargout(varargin{1}) > 0
        [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
    else
        feval(varargin{:});
    end
end


function [ training_seqs ] = getTrainingSequences( all_training_seqs, testing_seq, seq_conflicts )
%GETTRAININGSEQUENCES gives training seqs, given the complete set of
%   training seqs, the testing seq and conflicts between each sequence

   assert(isscalar(testing_seq), 'The testing sequence should be a single number');
   assert(iscell(seq_conflicts), 'The set of conflicts should be a cell array');
   
   % take out testing seq from training
   training_seqs = setdiff(all_training_seqs, testing_seq);
   
   % iterate over all conflicts and find if the testing seq has one
   for idx = 1:length(seq_conflicts)
       if any(seq_conflicts{idx} == testing_seq)
           training_seqs = setdiff(training_seqs, seq_conflicts{idx});
       end
   end
end


function [ testing_seq_groups full_training_seq ] = groupTestingSeqs( all_training_seqs, all_testing_seq, seq_conflicts )

   assert(iscell(seq_conflicts), 'The set of conflicts should be a cell array');
   testing_seq_groups = cell(0,2);
   full_training_seq = false(0,1);
   
   for idx = 1:length(all_testing_seq)
       testing_seq = all_testing_seq(idx);
       
       curr_training_seqs = getTrainingSequences( all_training_seqs, testing_seq, seq_conflicts );
       group_match = cellfun(@(x) all(ismember(curr_training_seqs,x)) && length(x)==length(curr_training_seqs), testing_seq_groups(:,2));
       assert(nnz(group_match) <= 1, 'The number of training set group matches can only be 0 or 1');
       
       if nnz(group_match) == 0
           testing_seq_groups{end+1,1} = testing_seq;
           testing_seq_groups{end,2} = curr_training_seqs;
           if all(ismember(all_training_seqs, curr_training_seqs))
               full_training_seq(end+1) = 1;
           else
               full_training_seq(end+1) = 0;
           end
       else
           testing_seq_groups{group_match,1} = [testing_seq_groups{group_match,1} testing_seq];
       end
   end
   
   assert(nnz(full_training_seq) <= 2, 'Something wrong in groupTestingSeqs()');
   testing_seq_groups = testing_seq_groups(:,1);
end
