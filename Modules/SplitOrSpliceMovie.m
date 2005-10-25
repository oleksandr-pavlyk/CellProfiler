function handles = SplitOrSpliceMovie(handles)

% Help for the SplitOrSplicMovie module:
% Category: File Processing
%
% See also <nothing relevant>.

% CellProfiler is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
%
% Developed by the Whitehead Institute for Biomedical Research.
% Copyright 2003,2004,2005.
%
% Authors:
%   Anne Carpenter <carpenter@wi.mit.edu>
%   Thouis Jones   <thouis@csail.mit.edu>
%   In Han Kang    <inthek@mit.edu>
%   Ola Friman     <friman@bwh.harvard.edu>
%   Steve Lowe     <stevelowe@alum.mit.edu>
%   Joo Han Chang  <joohan.chang@gmail.com>
%   Colin Clarke   <colinc@mit.edu>
%   Mike Lamprecht <mrl@wi.mit.edu>
%   Susan Ma       <xuefang_ma@wi.mit.edu>
%
% $Revision: 1725 $

%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%
drawnow

%%% Reads the current module number, because this is needed to find
%%% the variable values that the user entered.
CurrentModule = handles.Current.CurrentModuleNumber;
CurrentModuleNum = str2double(CurrentModule);

%textVAR01 = Do you want to split (create multiple smaller movies from one large movie) or splice (create one large movie from multiple smaller movies)?
%choiceVAR01 = Split
%choiceVAR01 = Splice
%inputtypeVAR01 = popupmenu
SplitOrSplice = char(handles.Settings.VariableValues{CurrentModuleNum,1});

%pathnametextVAR02 = Where are the existing avi-formatted movie files?
ExistingPath = char(handles.Settings.VariableValues{CurrentModuleNum,2});

%pathnametextVAR03 = Where do you want to put the resulting file(s)?
FinalPath = char(handles.Settings.VariableValues{CurrentModuleNum,3});

%textVAR04 = For SPLICE, what is the common text in your movie files? For SPLIT, what is the entire name, including extension, of the movie file to be split?
%defaultVAR04 = GFPstain.avi
TargetMovieFileName = char(handles.Settings.VariableValues{CurrentModuleNum,4});

%textVAR05 = For SPLIT, how many frames per movie do you want?
%defaultVAR05 = 100
FramesPerSplitMovie = str2num(char(handles.Settings.VariableValues{CurrentModuleNum,5}));

%textVAR06 = For SPLICE, what do you want to call the final movie?
%defaultVAR06 = GFPstainSPLICED.avi
FinalSpliceName = char(handles.Settings.VariableValues{CurrentModuleNum,6});

%textVAR07 = Note: This module is run by itself in a pipeline; there is no need to use a LoadImages or SaveImages module.

%%%VariableRevisionNumber = 2

%%%%%%%%%%%%%%%%%%%%%%%
%%% FILE PROCESSING %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

fieldname = ['FigureNumberForModule',CurrentModule];
ThisModuleFigureNumber = handles.Current.(fieldname);
if any(findobj == ThisModuleFigureNumber)
    close(ThisModuleFigureNumber)
end

if handles.Current.SetBeingAnalyzed == 1
    if strcmp(SplitOrSplice,'Split')
        AviMovieInfo = aviinfo(fullfile(ExistingPath,TargetMovieFileName));

        NumSplitMovies = ceil(AviMovieInfo.NumFrames/FramesPerSplitMovie);

        LastFrameRead = 0;
        for i = 1:NumSplitMovies
            [Pathname,FilenameWithoutExtension,Extension,ignore3] = fileparts(fullfile(ExistingPath,TargetMovieFileName));
            NewFileAndPathName = fullfile(FinalPath, [FilenameWithoutExtension, '_', num2str(i),Extension]);
            LastFrameToReadForThisFile = min(i*FramesPerSplitMovie,AviMovieInfo.NumFrames);
            LoadedRawImages = aviread(fullfile(ExistingPath,TargetMovieFileName),LastFrameRead+1:LastFrameToReadForThisFile);
            try movie2avi(LoadedRawImages,NewFileAndPathName)
            catch error('problem encountered during save')
                return
            end
            LastFrameRead = i*FramesPerSplitMovie;
        end
    else
        Filenames = CPretrieveMediaFileNames(ExistingPath,TargetMovieFileName,'N','E','Movie');
        %%% Checks whether any files are left.
        if isempty(Filenames)
            error(['Image processing was canceled because there are no image files with the text "', TargetMovieFileName, '" in the chosen directory (or subdirectories, if you requested them to be analyzed as well), according to the LoadImagesText module.'])
        end

        NewFileAndPathName = fullfile(FinalPath,FinalSpliceName);
        NewAviMovie = avifile(NewFileAndPathName);
        NumMovies = length(Filenames);

        for i = 1:NumMovies
            LoadedRawImages = aviread(fullfile(ExistingPath,char(Filenames(i))));
            try NewAviMovie = addframe(NewAviMovie,LoadedRawImages);
            catch error(['Problem encountered during save of ',NewFileAndPathName])
                return
            end
        end

        try NewAviMovie = close(NewAviMovie)
        catch error(['Problem encountered during save of ',NewFileAndPathName])
        end
    end
end