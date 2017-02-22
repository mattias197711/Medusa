<%!
    from medusa import app
    from medusa.common import Quality, qualityPresets, qualityPresetStrings
%>
<%
if not show is UNDEFINED:
    __quality = int(show.quality)
else:
    __quality = int(app.QUALITY_DEFAULT)
allowed_qualities, preferred_qualities = Quality.split_quality(__quality)
overall_quality = Quality.combine_qualities(allowed_qualities, preferred_qualities)
selected = None
%>
<select id="qualityPreset" name="quality_preset" class="form-control form-control-inline input-sm">
    <option value="0">Custom</option>
    % for curPreset in qualityPresets:
        <option value="${curPreset}" ${'selected="selected"' if curPreset == overall_quality else ''} ${('', 'style="padding-left: 15px;"')[qualityPresetStrings[curPreset].endswith("0p")]}>${qualityPresetStrings[curPreset]}</option>
    % endfor
</select>
<div id="customQualityWrapper">
    <div id="customQuality" style="padding-left: 0;">
        <p><b><strong>Preferred</strong></b> qualities will replace those in <b><strong>allowed</strong></b>, even if they are lower.</p>
        <div style="padding-right: 40px; text-align: left; float: left;">
            <h5>Allowed</h5>
            <% any_quality_list = filter(lambda x: x > Quality.NONE, Quality.qualityStrings) %>
            <select id="allowed_qualities" name="allowed_qualities" multiple="multiple" size="${len(any_quality_list)}" class="form-control form-control-inline input-sm">
            % for cur_quality in sorted(any_quality_list):
                <option value="${cur_quality}" ${'selected="selected"' if cur_quality in allowed_qualities else ''}>${Quality.qualityStrings[cur_quality]}</option>
            % endfor
            </select>
        </div>
        <div style="text-align: left; float: left;">
            <h5>Preferred</h5>
            <% preferred_quality_list = filter(lambda x: x >= Quality.SDTV and x < Quality.UNKNOWN, Quality.qualityStrings) %>
            <select id="preferred_qualities" name="preferred_qualities" multiple="multiple" size="${len(preferred_quality_list)}" class="form-control form-control-inline input-sm">
            % for cur_quality in sorted(preferred_quality_list):
                <option value="${cur_quality}" ${'selected="selected"' if cur_quality in preferred_qualities else ''}>${Quality.qualityStrings[cur_quality]}</option>
            % endfor
            </select>
        </div>
    </div>
    <div id="quality_explanation">
        <h5><b>Quality setting explanation:</b></h5>
        <h5 id="allowed_text">This will download <b>any</b> of these qualities and then stops searching: <label id="allowed_explanation">${', '.join([Quality.qualityStrings[i] for i in allowed_qualities])}</label></h5>
        <h5 id="preferred_text1">Downloads <b>any</b> of these qualities: <label id="allowed_preferred_explanation">${', '.join([Quality.qualityStrings[i] for i in allowed_qualities + preferred_qualities])}</label></h5>
        <h5 id="preferred_text2">But it will stop searching when one of these is downloaded:  <label id="preferred_explanation">${', '.join([Quality.qualityStrings[i] for i in preferred_qualities])}</label></h5>
    </div>
    <div>
        <h5 class="red-text" id="backlogged_episodes"></h5>
    </div>
    <div id="archive" style="display: none;">
        <h5>
            <b>
                Archive downloaded episodes to avoid unnecessarily increasing
                your backlog:
            </b>
        </h5>
        <input class="btn btn-inline" type="button" id="archiveEpisodes" value="Archive episodes" />
        <br />
        <h5>
            Or manually archive episodes with
            <b><a href="manage/episodeStatuses/">Episode Status Management</a></b>
        </h5>
        <h5 id="archivedStatus"></h5>
    </div>
</div>
