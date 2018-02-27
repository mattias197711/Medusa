<%inherit file="/layouts/main.mako"/>
<%!
    import adba
    import json
    from medusa import app, common
    from medusa.common import SKIPPED, WANTED, UNAIRED, ARCHIVED, IGNORED, SNATCHED, SNATCHED_PROPER, SNATCHED_BEST, FAILED
    from medusa.common import statusStrings
    from medusa.helper import exceptions
    from medusa.indexers.indexer_api import indexerApi
    from medusa.indexers.utils import mappings
    from medusa import scene_exceptions
%>
<%block name="metas">
<meta data-var="show.is_anime" data-content="${show.is_anime}">
</%block>
<%block name="content">
<input type="hidden" id="indexer-name" value="${show.indexer_name}" />
<input type="hidden" id="series-id" value="${show.indexerid}" />
<input type="hidden" id="series-slug" value="${show.slug}" />
% if not header is UNDEFINED:
    <h1 class="header">${header}</h1>
% else:
    <h1 class="title">${title}</h1>
% endif
<div id="config-content">
    <div id="config" v-bind:class="{ summaryFanArt: config.fanartBackground }">
        <form v-on:submit.prevent="storeConfig">
        <div id="config-components">
            <ul>
                ## @TODO: Fix this stupid hack
                <script>document.write('<li><a href="' + document.location.href + '#core-component-group1">Main</a></li>');</script>
                <script>document.write('<li><a href="' + document.location.href + '#core-component-group2">Format</a></li>');</script>
                <script>document.write('<li><a href="' + document.location.href + '#core-component-group3">Advanced</a></li>');</script>
            </ul>
            <div id="core-component-group1">
                <div class="component-group">
                    <h3>Main Settings</h3>
                    <fieldset class="component-group-list">
                        <div class="field-pair">
                            <label for="location">
                                <span class="component-title">Show Location</span>
                                <span class="component-desc">
                                    <input type="hidden" name="indexername" id="form-indexername" :value="seriesObj.indexer" />
                                    <input type="hidden" name="seriesid" id="form-seriesid" :value="seriesObj.id[seriesObj.indexer]" />
                                    <input type="text" name="location" id="location" :value="seriesObj.config.location" class="form-control form-control-inline input-sm input350"/>
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="qualityPreset">
                                <span class="component-title">Preferred Quality</span>
                                <span class="component-desc">
                                    <% allowed_qualities, preferred_qualities = common.Quality.split_quality(int(show.quality)) %>
                                    <%include file="/inc_qualityChooser.mako"/>
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="defaultEpStatusSelect">
                                <span class="component-title">Default Episode Status</span>
                                <span class="component-desc">
                                    <select name="defaultEpStatus" id="defaultEpStatusSelect" class="form-control form-control-inline input-sm">
                                        % for cur_status in [WANTED, SKIPPED, IGNORED]:
                                        <option value="${cur_status}" ${'selected="selected"' if cur_status == show.default_ep_status else ''}>${statusStrings[cur_status]}</option>
                                        % endfor
                                    </select>
                                    <div class="clear-left"><p>This will set the status for future episodes.</p></div>
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="indexerLangSelect">
                                <span class="component-title">Info Language</span>
                                <span class="component-desc">
                                    <select name="indexer_lang" id="indexerLangSelect" class="form-control form-control-inline input-sm bfh-languages" data-blank="false" :data-language="seriesObj.language" :data-available="availableLanguagesAvailable" @change="storeConfig($event)"></select>
                                    <div class="clear-left"><p>This only applies to episode filenames and the contents of metadata files.</p></div>
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="subtitles">
                                <span class="component-title">Subtitles</span>
                                <span class="component-desc">
                                    <input type="checkbox" id="subtitles" name="subtitles" v-model="seriesObj.config.subtitlesEnabled" @change="storeConfig($event)"/> search for subtitles
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="paused">
                                <span class="component-title">Paused</span>
                                <span class="component-desc">
                                    <input type="checkbox" id="paused" name="paused" v-model="seriesObj.config.paused" @change="storeConfig($event)"/> pause this show (Medusa will not download episodes)
                                </span>
                            </label>
                        </div>
                    </fieldset>
                </div>
            </div>
            <div id="core-component-group2">
                <div class="component-group">
                    <h3>Format Settings</h3>
                    <fieldset class="component-group-list">
                        <div class="field-pair">
                            <label for="airbydate">
                                <span class="component-title">Air by date</span>
                                <span class="component-desc">
                                    <input type="checkbox" id="airbydate" name="air_by_date" v-model="seriesObj.config.paused" @change="storeConfig($event)" /> check if the show is released as Show.03.02.2010 rather than Show.S02E03.<br>
                                    <span style="color:rgb(255, 0, 0);">In case of an air date conflict between regular and special episodes, the later will be ignored.</span>
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="anime">
                                <span class="component-title">Anime</span>
                                <span class="component-desc">
                                    <input type="checkbox" id="anime" name="anime" v-model="seriesObj.config.anime" @change="storeConfig($event)"> check if the show is Anime and episodes are released as Show.265 rather than Show.S02E03<br>
                                    % if show.is_anime:
                                        <%include file="/inc_blackwhitelist.mako"/>
                                    % endif
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="sports">
                                <span class="component-title">Sports</span>
                                <span class="component-desc">
                                    <input type="checkbox" id="sports" name="sports" v-model="seriesObj.config.sports" @change="storeConfig($event)"/> check if the show is a sporting or MMA event released as Show.03.02.2010 rather than Show.S02E03<br>
                                    <span style="color:rgb(255, 0, 0);">In case of an air date conflict between regular and special episodes, the later will be ignored.</span>
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="season_folders">
                                <span class="component-title">Season folders</span>
                                <span class="component-desc">
                                    <input type="checkbox" id="season_folders" name="flatten_folders" v-model="seriesObj.config.flattenFolders" @change="storeConfig($event)"/> group episodes by season folder (uncheck to store in a single folder)
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="scene">
                                <span class="component-title">Scene Numbering</span>
                                <span class="component-desc">
                                    <input type="checkbox" id="scene" name="scene" v-model="seriesObj.config.scene" @change="storeConfig($event)"/> search by scene numbering (uncheck to search by indexer numbering)
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="dvdorder">
                                <span class="component-title">DVD Order</span>
                                <span class="component-desc">
                                    <input type="checkbox" id="dvdorder" name="dvd_order" v-model="seriesObj.config.dvdOrder" @change="storeConfig($event)"/> use the DVD order instead of the air order<br>
                                    <div class="clear-left"><p>A "Force Full Update" is necessary, and if you have existing episodes you need to sort them manually.</p></div>
                                </span>
                            </label>
                        </div>
                    </fieldset>
                </div>
            </div>
            <div id="core-component-group3">
                <div class="component-group">
                    <h3>Advanced Settings</h3>
                    <fieldset class="component-group-list">
                        <div class="field-pair">
                            <label for="rls_ignore_words">
                                <span class="component-title">Ignored Words</span>
                                <span class="component-desc">
                                    <input type="text" id="rls_ignore_words" name="rls_ignore_words" id="rls_ignore_words" value="${show.rls_ignore_words}" class="form-control form-control-inline input-sm input350"/><br>
                                    <div class="clear-left">
                                        <p>comma-separated <i>e.g. "word1,word2,word3"</i></p>
                                        <p>Search results with one or more words from this list will be ignored.</p>
                                    </div>
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="rls_require_words">
                                <span class="component-title">Required Words</span>
                                <span class="component-desc">
                                    <input type="text" id="rls_require_words" name="rls_require_words" id="rls_require_words" value="${show.rls_require_words}" class="form-control form-control-inline input-sm input350"/><br>
                                    <div class="clear-left">
                                        <p>comma-separated <i>e.g. "word1,word2,word3"</i></p>
                                        <p>Search results with no words from this list will be ignored.</p>
                                    </div>
                                </span>
                            </label>
                        </div>
                        <div class="field-pair">
                            <label for="SceneName">
                                <span class="component-title">Scene Exception</span>
                                <span class="component-desc">
                                    <input type="text" id="SceneName" class="form-control form-control-inline input-sm input200"/><input class="btn btn-inline" type="button" value="Add" id="addSceneName" /><br><br>
                                    <div class="pull-left">
                                        <select id="exceptions_list" name="exceptions_list" multiple="multiple" style="min-width:200px;height:99px;">
                                            <option v-for="exception in exceptions" :value="exception.series_name">
                                                {{exception.series_name}} ({{exception.episode_search_template}})
                                            </option>
                                        </select>
                                        <div><input id="removeSceneName" value="Remove" class="btn float-left" type="button" style="margin-top: 10px;"/></div>
                                    </div>
                                    <div class="clear-left"><p>This will affect episode search on NZB and torrent providers. This list appends to the original show name.</p></div>
                                </span>
                            </label>
                        </div>
                    </fieldset>
                </div>
            </div>
        </div>
        <br>
        <input id="submit" type="submit" value="Save Changes" class="btn pull-left config_submitter button">
        </form>
    </div>
</div>

</%block>
<%block name="scripts">
    <script type="text/javascript" src="js/quality-chooser.js?${sbPID}"></script>
    <script type="text/javascript" src="js/edit-show.js"></script>
% if show.is_anime:
    <script type="text/javascript" src="js/blackwhite.js?${sbPID}"></script>
% endif
<script src="js/lib/vue.js"></script>
<%
    seriesObj = json.dumps(show.to_json());
%>
<script>
// register the component
Vue.component('my-component', {
  template: '<div>A custom component!</div>'
})
var startVue = function() {
    const app = new Vue({
        el: '#config-content',
        data() {
            const seriesObj = ${seriesObj};
            const seriesSlug = seriesObj.id.slug;
            const exceptions = seriesObj.config.aliases;
            return {
                config: MEDUSA.config,
                exceptions: exceptions,
                seriesSlug: seriesSlug,
                seriesObj: seriesObj,
                subtitles: seriesObj.config.subtitlesEnabled,
                folders: seriesObj.config.flattenFolders
            }
        },
        methods: {
            anonRedirect: function(e) {
                e.preventDefault();
                window.open(MEDUSA.info.anonRedirect + e.target.href, '_blank');
            },
            prettyPrintJSON: function(x) {
                return JSON.stringify(x, undefined, 4)
            },
            storeConfig(evt) {
                api.patch('config/main', {
                    config: {
                        dvdOrder: this.seriesObj.config.dvdOrder,
                        flattenFolders: this.seriesObj.config.flattenFolders,
                        anime: this.seriesObj.config.anime,
                        scene: this.seriesObj.config.scene,
                        sports: this.seriesObj.config.sports,
                        paused: this.seriesObj.config.paused,
                        location: this.seriesObj.config.location,
                        airByDate: this.seriesObj.config.airByDate,
                        subtitlesEnabled: this.seriesObj.config.subtitlesEnabled
                    }
                }).then(response => {
                    log.info(response);
                }).catch(err => {
                    log.error(err);
                });
            }
        },
        computed: {
            availableLanguagesAvailable: function() {
                return this.config.indexers.config.main.validLanguages.join(',');
            }   
        }
    });
    $('[v-cloak]').removeAttr('v-cloak');
};
</script>
</%block>
