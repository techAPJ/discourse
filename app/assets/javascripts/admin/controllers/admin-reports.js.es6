import { exportEntity } from 'discourse/lib/export-csv';
import { outputExportResult } from 'discourse/lib/export-result';
import Report from 'admin/models/report';
import Group from 'discourse/models/group';

export default Ember.Controller.extend({
  viewMode: 'table',
  viewingTable: Em.computed.equal('viewMode', 'table'),
  viewingBarChart: Em.computed.equal('viewMode', 'barChart'),
  startDate: null,
  endDate: null,
  categoryId: null,
  groupId: null,
  refreshing: false,

  categoryOptions: function() {
    var arr = [{name: I18n.t('category.all'), value: 'all'}];
    return arr.concat( Discourse.Site.currentProp('sortedCategories').map(function(i) { return {name: i.get('name'), value: i.get('id') }; }) );
  }.property(),

  groupOptions: function() {
    var arr = [{name: I18n.t('admin.dashboard.reports.groups'), value: 'all'}];
    return arr.concat( this.site.groups.map(function(i) { return {name: i['name'], value: i['id'] }; }) );
  }.property(),

  showGroupOptions:function() {
    return this.get("model.type") == "visits" || this.get("model.type") == "signups" || this.get("model.type") == "profile_views"
  }.property("model.type"),

  actions: {
    refreshReport() {
      var q;
      this.set("refreshing", true);

      q = Report.find(this.get("model.type"), this.get("startDate"), this.get("endDate"), this.get("categoryId"), this.get("groupId"));
      q.then(m => this.set("model", m)).finally(() => this.set("refreshing", false));
    },

    viewAsTable() {
      this.set('viewMode', 'table');
    },

    viewAsBarChart() {
      this.set('viewMode', 'barChart');
    },

    exportCsv() {
      exportEntity('report', {
        name: this.get("model.type"),
        start_date: this.get('startDate'),
        end_date: this.get('endDate'),
        category_id: this.get('categoryId') === 'all' ? undefined : this.get('categoryId'),
        group_id: this.get('groupId') === 'all' ? undefined : this.get('groupId')
      }).then(outputExportResult);
    }
  }
});
