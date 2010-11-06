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



function [ testing_seqs ] = getNoConflictTestingSequences( all_training_seqs, all_testing_seq, seq_conflicts )
%GETTRAININGSEQUENCES gives training seqs, given the complete set of
%   training seqs, the testing seq and conflicts between each sequence

   assert(iscell(seq_conflicts), 'The set of conflicts should be a cell array');
   
   % take out testing seq from training
   testing_seqs = setdiff(all_testing_seq, all_training_seqs);
   
   % iterate over conflicts and keep those which match with training seq
   remove = false(size(testing_seqs));
   for idx = 1:length(testing_seqs)
       valid_conflicts = seq_conflicts(cellfun(@(x) any(x == testing_seqs(idx)), seq_conflicts));
       seq_to_check = horzcat(valid_conflicts{:});
       if any(ismember(all_training_seqs, seq_to_check))
           remove(idx) = 1;
       end
   end
   
   testing_seqs = testing_seqs(~remove);
end

