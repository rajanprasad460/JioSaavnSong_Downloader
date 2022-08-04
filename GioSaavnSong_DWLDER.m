clc;
clear;

%% Description
%% This module will download songs from the Giosaavan website either specified by the
%% ALBUM Name or ARTIST Name
%% o_search_text is either the album name or the artist name

%% User Input section
% o_search_text = 'Kaho Naa Pyar Hai';
% o_search_text = 'Mangal Bhavan Amangal Hari';
% o_search_text = 'Jai Jai Shri Ram';
% o_search_text = 'Uttar Ramayan';
% o_search_text = 'Kavita Krishnamurti Subramaniam Songs';
% o_search_text = 'Ravindra Jain Songs';
% o_search_text = 'Ishq (Original Motion Picture Soundtrack)';
o_search_text = 'Guru (Original Motion Picture Soundtrack)';

o_search_type = 'ALBUM';
% o_search_type = 'ARTIST';

%%  Actual progress section
searchtext = strrep(o_search_text,' ','+');

if strcmp(o_search_type,'ALBUM')
    url_m = strcat('https://www.jiosaavn.com/api.php?p=1&q=',searchtext,'&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=20&__call=search.getAlbumResults');
elseif strcmp(o_search_type,'ARTIST')
    url_m = strcat('https://www.jiosaavn.com/api.php?p=1&q=',searchtext,'&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=20&__call=search.getArtistResults');
else
    warning('Specify type of result required');
end

%% Read the details of the specified search
mypage_m = webread(url_m);
mydata_m = jsondecode(mypage_m);
%% Extract the result and work on it
for i = 1:length(mydata_m.results)
    if contains(mydata_m.results(i).title,o_search_text)
        c_folder = strcat(cd,'\',strrep(mydata_m.results(i).title,' ','_'));
        %% If the folder doesn't exist, create it
        if ~exist(c_folder,"dir")
            mkdir(c_folder)
        end
        tokens_1 =  strsplit(mydata_m.results(i).perma_url,'/');
        tokens_1 = tokens_1{1,end};
        %====== Url to specific album/artist  ========================
        if strcmp(o_search_type,'ALBUM')
            url = strcat('https://www.jiosaavn.com/api.php?__call=webapi.get&api_version=4&_format=json&_marker=0&ctx=web6dot0&token=',tokens_1,'&type=album');
        end
        if strcmp(o_search_type,'ARTIST')
            url = strcat('https://www.jiosaavn.com/api.php?__call=webapi.get&api_version=4&_format=json&_marker=0&ctx=web6dot0&token=',tokens_1,'&type=artist');
        end
        %% ======= Read all the songs of specific album/artist ==================
        mypage = webread(url);
        mydata = jsondecode(mypage);

        %% ============ Download all songs of the specific album/artist if allowed ======
        for j =1:length(mydata.list)
            % Identifying the encrypted media url
            u_id = urlencoder(mydata.list(j).more_info.encrypted_media_url)  ;
            if length(string(u_id)) ==1
                %=========== Downloading authorized download link for that
                %encrypted url and saving as txt file
                down_url = strcat('curl "https://www.jiosaavn.com/api.php?__call=song.generateAuthToken&url=',u_id,'&bitrate=128&api_version=4&_format=json&ctx=web6dot0&_marker=0">"',c_folder,'\temp_url.txt"');
                system(down_url);
                %% Reading the downloaded file
                fileID = fopen(strcat(c_folder,'\temp_url.txt'),'r');
                formatSpec = '%s';
                auth_url_text = fscanf(fileID,formatSpec);
                fclose(fileID);
                delete(strcat(c_folder,'\temp_url.txt'));
                %% Correcting the link to find actual download link and downloading it==
                add_url = string(extractBetween(auth_url_text,'.com','?'));
                add_url = strrep(add_url,'\','');
                if ~isempty(add_url)

                    try
                        filename = strcat(c_folder,'\',strrep(mydata_m.results(j).title,' ','_'),'.mp3');
                        if ~isfile(filename)
                            url_d = strcat('curl "https://sklktecdnems02.cdnsrv.jio.com/jiosaavn.cdn.jio.com/',add_url,'">"',c_folder,'\',strrep(mydata_m.results(j).title,' ','_'),'.mp3" & exit &');
                            system(url_d);
                        end
                    catch
                        filename = strcat(c_folder,'\',matlab.lang.makeValidName(mydata_m.results(j).title),'.mp3');
                        if ~isfile(filename)
                            url_d = strcat('curl "https://sklktecdnems02.cdnsrv.jio.com/jiosaavn.cdn.jio.com/',add_url,'">"',c_folder,'\',matlab.lang.makeValidName(mydata_m.results(j).title),'.mp3" & exit &');
                            system(url_d);
                        end
                    end

                end
            end
            if strcmp(o_search_type,'ALBUM')
                progressupdater(j,length(mydata.list),sprintf('Downloading Songs [%d/%d]',i,length(mydata_m.results)));
            end
            if strcmp(o_search_type,'ARTIST')
                progressupdater(j,length(mydata.list),sprintf('Downloading Songs [%d]',i));
            end
        end
    end
end
