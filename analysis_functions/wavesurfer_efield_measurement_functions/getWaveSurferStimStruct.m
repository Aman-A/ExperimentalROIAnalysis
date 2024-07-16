function [stim,num_sweeps] = getWaveSurferStimStruct(rec_file)

s = ws.loadDataFile(rec_file);
stim_map_index = s.header.StimulusLibrary.SelectedOutputableIndex;
chan_index = find(strncmp(s.header.StimulusLibrary.Maps.(sprintf('element%g',stim_map_index)).ChannelName,'AO0',3));
stim_index = s.header.StimulusLibrary.Maps.(sprintf('element%g',stim_map_index)).IndexOfEachStimulusInLibrary.(sprintf('element%g',chan_index));
stim_elems = s.header.StimulusLibrary.Stimuli;
stim_elem = stim_elems.(sprintf('element%g',stim_index));
stim = stim_elem.Delegate;
num_sweeps = s.header.NSweepsPerRun;
end