(window.webpackJsonp=window.webpackJsonp||[]).push([[3],{203:function(o,e,n){"use strict";n.r(e);var a=n(7),t=n(62),s=n(63),c=n(66),i=n(23),d=n(19),l=n(11);a.a.config.devtools=!0,a.a.config.performance=!0,a.a.use(t.a),a.a.use(s.a),Object(c.b)();const p=new a.a({name:"App",router:i.a,store:d.a,data:()=>({globalLoading:!1,pageComponent:!1}),mounted(){if(l.c&&console.log("App Mounted!"),!window.location.pathname.includes("/login")){const{$store:o}=this;Promise.all([o.dispatch("login",{username:window.username}),o.dispatch("getConfig")]).then(([o,e])=>{l.c&&console.log("App Loaded!");const n=new CustomEvent("medusa-config-loaded",{detail:e.main});window.dispatchEvent(n)}).catch(o=>{console.debug(o),alert("Unable to connect to Medusa!")})}}}).$mount("#vue-wrap");e.default=p}},[[203,1,0,2]]]);
//# sourceMappingURL=app.js.map