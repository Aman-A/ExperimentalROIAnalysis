function stim = getWaveSurferStimStruct(rec_file)

s = ws.loadDataFile(rec_file);
stim_elems = s.header.StimulusLibrary.Stimuli;
stim_elem_names = fieldnames(stim_elems);
stim_elem_ind = s.header.StimulationTriggerIndex;
stim_elem = stim_elems.(stim_elem_names{stim_elem_ind});
stim = stim_elem.Delegate;

end