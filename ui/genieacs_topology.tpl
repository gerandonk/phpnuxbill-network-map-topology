{include file="sections/header.tpl"}

<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<style>
{literal}#map { height: 600px; width: 100%; border-radius: 8px; }
.custom-marker { cursor: pointer; }
.custom-marker:hover .marker-icon { transform: rotate(-45deg) scale(1.15); }
@keyframes pulse { 0%,100% { transform: scale(1); opacity: 1; } 50% { transform: scale(1.3); opacity: 0.7; } }
@keyframes dash-run { 0% { stroke-dashoffset: 24; } 100% { stroke-dashoffset: 0; } }
.connection-online { stroke-dasharray: 8 4; animation: dash-run 0.8s linear infinite; }
.connection-offline { stroke-dasharray: 8 4; animation: dash-run 1.2s linear infinite; }
.connection-unknown { stroke-dasharray: 4 4; animation: dash-run 1.5s linear infinite; }
.connection-p2p { stroke-dasharray: 12 6; animation: dash-run 1s linear infinite; }
{/literal}</style>

<div class="row">
    <div class="col-md-12">
        <div class="card">
            <div class="card-body">
                <button class="btn btn-primary" onclick="showAddItemModal()"><i class="glyphicon glyphicon-plus"></i> Add</button>
                <button class="btn btn-info pull-right" onclick="refreshMap()"><i class="glyphicon glyphicon-refresh"></i> Refresh</button>
                <div class="btn-group pull-right" style="margin-right:8px">
                    <button class="btn btn-sm btn-default" onclick="showItemList('server')">Server <span class="badge" id="server-count">0</span></button>
                    <button class="btn btn-sm btn-default" onclick="showItemList('olt')">OLT <span class="badge" id="olt-count">0</span></button>
                    <button class="btn btn-sm btn-default" onclick="showItemList('odc')">ODC <span class="badge" id="odc-count">0</span></button>
                    <button class="btn btn-sm btn-default" onclick="showItemList('odp')">ODP <span class="badge" id="odp-count">0</span></button>
                    <button class="btn btn-sm btn-default" onclick="showItemList('onu')">ONU <span class="badge" id="onu-count">0</span></button>
                    <button class="btn btn-sm btn-default" onclick="showItemList('switch')">Switch <span class="badge" id="switch-count">0</span></button>
                    <button class="btn btn-sm btn-default" onclick="showItemList('htb')">HTB <span class="badge" id="htb-count">0</span></button>
                </div>
                <div class="btn-group pull-right" style="margin-right:8px" id="map-type-group">
                    <button class="btn btn-sm btn-primary" data-map="street" onclick="switchMapType('street')">Street</button>
                    <button class="btn btn-sm btn-default" data-map="satellite" onclick="switchMapType('satellite')">Satellite</button>
                    <button class="btn btn-sm btn-default" data-map="hybrid" onclick="switchMapType('hybrid')">Hybrid</button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-12">
        <div class="card">
            <div class="card-body" style="padding:4px">
                <div id="map"></div>
            </div>
        </div>
    </div>
</div>

<!-- Add Item Modal -->
<div class="modal fade" id="addItemModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="glyphicon glyphicon-plus-sign"></i> Add Network Item</h5>
                <button type="button" class="close" data-dismiss="modal">&times;</button>
            </div>
            <div class="modal-body">
                <form id="form-add-item">
                    <table style="width:100%">
                        <tr><td style="width:140px;padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">Item Type</label></td>
                            <td style="padding:4px 0"><select name="item_type" class="form-control" required onchange="updateItemForm(this.value)">
                                <option value="">Select Type</option>
                                <option value="server">Server</option>
                                <option value="olt">OLT</option>
                                <option value="odc">ODC</option>
                                <option value="odp">ODP</option>
                                <option value="onu">ONU</option>
                                <option value="switch">Switch/Hub</option>
                                <option value="htb">HTB</option>
                            </select></td></tr>
                        <tr><td style="padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">Name</label></td>
                            <td style="padding:4px 0"><input type="text" name="name" class="form-control" required></td></tr>
                        <tr><td style="padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">Latitude</label></td>
                            <td style="padding:4px 0"><input type="text" step="any" name="latitude" class="form-control" required></td></tr>
                        <tr><td style="padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">Longitude</label></td>
                            <td style="padding:4px 0"><input type="text" step="any" name="longitude" class="form-control" required></td></tr>
                    </table>
                    <hr style="margin:6px 0">
                    <div id="dynamic-fields"></div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary" onclick="addItem()">Add Item</button>
            </div>
        </div>
    </div>
</div>

<!-- Edit Item Modal -->
<div class="modal fade" id="editItemModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="glyphicon glyphicon-edit"></i> Edit Network Item</h5>
                <button type="button" class="close" data-dismiss="modal">&times;</button>
            </div>
            <div class="modal-body">
                <form id="form-edit-item">
                    <input type="hidden" name="item_id">
                    <table style="width:100%">
                        <tr><td style="width:140px;padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">Item Type</label></td>
                            <td style="padding:4px 0"><input type="text" name="item_type" class="form-control" readonly></td></tr>
                        <tr><td style="padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">Name</label></td>
                            <td style="padding:4px 0"><input type="text" name="name" class="form-control" required></td></tr>
                        <tr><td style="padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">Latitude</label></td>
                            <td style="padding:4px 0"><input type="text" step="any" name="latitude" class="form-control"></td></tr>
                        <tr><td style="padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">Longitude</label></td>
                            <td style="padding:4px 0"><input type="text" step="any" name="longitude" class="form-control"></td></tr>
                    </table>
                    <hr style="margin:6px 0">
                    <div id="edit-dynamic-fields"></div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary" onclick="updateItem()">Update</button>
            </div>
        </div>
    </div>
</div>

<!-- Server Links Modal -->
<div class="modal fade" id="serverLinksModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="glyphicon glyphicon-link"></i> Manage Server Links</h5>
                <button type="button" class="close" data-dismiss="modal">&times;</button>
            </div>
            <div class="modal-body">
                <form id="form-server-links">
                    <input type="hidden" name="item_id">
                    <table style="width:100%">
                        <tr><td style="width:140px;padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">ISP Link</label></td>
                            <td style="padding:4px 0"><input type="text" name="isp_link" class="form-control" placeholder="e.g. 10.0.0.1"></td></tr>
                        <tr><td style="padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">MikroTik Device</label></td>
                            <td style="padding:4px 0"><input type="text" name="mikrotik_device_id" class="form-control" placeholder="GenieACS device ID"></td></tr>
                        <tr><td style="padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">OLT Link</label></td>
                            <td style="padding:4px 0"><input type="text" name="olt_link" class="form-control" placeholder="e.g. 10.0.0.2"></td></tr>
                    </table>
                    <hr style="margin:6px 0">
                    <div id="pon-output-power-container"></div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary" onclick="saveServerLinks()">Save Links</button>
            </div>
        </div>
    </div>
</div>

<!-- Item List Modal -->
<div class="modal fade" id="itemListModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="itemListModalTitle">Items</h5>
                <button type="button" class="close" data-dismiss="modal">&times;</button>
            </div>
            <div class="modal-body" id="item-list-container"></div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
var items = {$items|default:'[]'};
{literal}
var map = null;
var markers = {};
var polylines = [];
var polylineData = {};
var allMapItems = [];
var locationPointer = null;
var currentMapType = 'street';
var tileLayers = {};

document.addEventListener('DOMContentLoaded', function() {
    initMap();
});

var iconConfigs = {
    server: { icon: 'glyphicon glyphicon-cloud', bg: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' },
    olt: { icon: 'glyphicon glyphicon-signal', bg: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)' },
    odc: { icon: 'glyphicon glyphicon-inbox', bg: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)' },
    odp: { icon: 'glyphicon glyphicon-th', bg: 'linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%)' },
    onu: { icon: 'glyphicon glyphicon-home', bg: 'linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)' },
    switch: { icon: 'glyphicon glyphicon-transfer', bg: 'linear-gradient(135deg, #fbc2eb 0%, #a6c1ee 100%)' },
    htb: { icon: 'glyphicon glyphicon-tower', bg: 'linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%)' }
};

function getItemIcon(type, status) {
    var cfg = iconConfigs[type] || iconConfigs.onu;
    var sc = status === 'online' ? '#10b981' : status === 'offline' ? '#ef4444' : '#6b7280';
    return L.divIcon({
        html: '<div class="custom-marker"><div class="marker-icon" style="background:' + cfg.bg + ';width:36px;height:36px;border-radius:50% 50% 50% 0;transform:rotate(-45deg);display:flex;align-items:center;justify-content:center;box-shadow:0 3px 6px rgba(0,0,0,0.3);border:3px solid ' + sc + '"><i class="' + cfg.icon + '" style="font-size:14px;color:white;transform:rotate(45deg)"></i></div></div>',
        className: '', iconSize: [36, 36], iconAnchor: [18, 36]
    });
}

function initMap() {
    map = L.map('map').setView([-6.2088, 106.8456], 13);

    tileLayers.street = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, label: 'Street' });
    tileLayers.satellite = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', { maxZoom: 19, label: 'Satellite' });
    tileLayers.hybrid = L.layerGroup([
        L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', { maxZoom: 19 }),
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, opacity: 0.4 })
    ]);

    tileLayers.street.addTo(map);

    map.on('click', function(e) {
        if (locationPointer) map.removeLayer(locationPointer);
        locationPointer = L.marker(e.latlng, { draggable: true }).addTo(map);
        locationPointer.on('dragend', function(ev) {
            updateFormCoords(ev.target.getLatLng());
        });
        updateFormCoords(e.latlng);
    });

    loadMap(items);
}

function switchMapType(type) {
    if (type === currentMapType) return;
    Object.keys(tileLayers).forEach(function(k) {
        map.removeLayer(tileLayers[k]);
    });
    tileLayers[type].addTo(map);
    currentMapType = type;
    var btns = document.querySelectorAll('#map-type-group .btn');
    for (var i = 0; i < btns.length; i++) {
        btns[i].className = 'btn btn-sm ' + (btns[i].getAttribute('data-map') === type ? 'btn-primary' : 'btn-default');
    }
}

function updateFormCoords(latlng) {
    var f = document.getElementById('form-add-item');
    if (f) { f.latitude.value = latlng.lat.toFixed(8); f.longitude.value = latlng.lng.toFixed(8); }
}

function loadMap(data) {
    allMapItems = data || [];
    // Clear existing
    Object.keys(markers).forEach(function(k) { markers[k].remove(); });
    markers = {};
    polylines.forEach(function(p) { p.remove(); });
    polylines = [];
    polylineData = {};

    allMapItems.forEach(function(item) {
        var icon = getItemIcon(item.item_type, item.status);
        var m = L.marker([parseFloat(item.latitude), parseFloat(item.longitude)], { icon: icon, draggable: true }).addTo(map);
        m.itemData = item;
        m.bindPopup(getPopupContent(item), { maxWidth: 320 });
        m.on('popupopen', function() { loadPopupDetails(item); });
        m.on('dragend', function(e) {
            var pos = e.target.getLatLng();
            updateItemPosition(item.id, pos.lat, pos.lng);
        });
        markers[item.id] = m;
    });

    // Draw connections
    allMapItems.forEach(function(item) {
        if (item.parent_id && markers[item.id]) {
            var pm = markers[item.parent_id];
            if (!pm) {
                // Try grandparent
                var pItem = allMapItems.find(function(i) { return i.id == item.parent_id; });
                if (pItem && pItem.parent_id) pm = markers[pItem.parent_id];
            }
            if (pm) {
                var cs = 'unknown', clr = '#6b7280', w = 4;
                // Server-to-server P2P connection
                if (pm.itemData.item_type === 'server' && item.item_type === 'server') {
                    clr = '#e83e8c'; w = 5; cs = 'p2p';
                } else if (pm.itemData.status === 'online' && item.status === 'online') { cs = 'online'; clr = '#10b981'; w = 4; }
                else if (pm.itemData.status === 'offline' || item.status === 'offline') { cs = 'offline'; clr = '#ef4444'; w = 4; }
                var coords = [pm.getLatLng(), markers[item.id].getLatLng()];
                var p = L.polyline(coords, { color: clr, weight: w, opacity: 0.9, className: 'connection-' + cs }).addTo(map);
                polylines.push(p);
                polylineData[item.parent_id + '-' + item.id] = { mainPolyline: p, parentId: item.parent_id, childId: item.id };
            }
        }
    });

    updateCounters();
}

function getPopupContent(item) {
    var se = item.status === 'online' ? '🟢' : item.status === 'offline' ? '🔴' : '⚪';
    var h = '<div style="min-width:200px"><h6><strong>' + item.name + ' ' + se + '</strong></h6>';
    h += '<p><small>Type: <strong>' + item.item_type.toUpperCase() + '</strong></small></p>';

    if (item.item_type === 'server') {
        var p = item.properties || {};
        h += '<div id="server-chain-' + item.id + '"><small>Loading connections...</small></div>';
        h += '<hr><button class="btn btn-xs btn-info" onclick="manageServerLinks(' + item.id + ')">Edit Server Links</button>';
    }
    if (item.item_type === 'odc' && item.config) {
        h += '<p><small>Ports: ' + (item.config.port_count || 'N/A') + '</small></p>';
        h += '<p><small>RX: ' + (item.config.calculated_power || 'N/A') + ' dBm</small></p>';
    }
    if (item.item_type === 'odp' && item.config) {
        h += '<p><small>Ports: ' + (item.config.port_count || 'N/A') + '</small></p>';
        h += '<p><small>Input: ' + (item.config.input_power || 'N/A') + ' dBm</small></p>';
        h += '<div id="odp-ports-' + item.id + '"><small>Loading ports...</small></div>';
    }
    if (item.item_type === 'onu' && item.genieacs_device_id) {
        h += '<div id="onu-details-' + item.id + '"><small>Loading device info...</small></div>';
    }
    if (item.item_type === 'switch' || item.item_type === 'htb') {
        if (item.config && item.config.customer_name) h += '<p><small>Customer: ' + item.config.customer_name + '</small></p>';
        h += '<p><small>Ports: ' + (item.config && item.config.port_count || 'N/A') + '</small></p>';
    }
    var en = item.name.replace(/'/g, "\\'");
    h += '<hr><div class="btn-group btn-group-xs" style="width:100%">';
    h += '<a class="btn btn-success btn-xs" href="https://www.google.com/maps?q=' + item.latitude + ',' + item.longitude + '" target="_blank">Google Maps</a>';
    h += '<button class="btn btn-primary btn-xs" onclick="editItemClick(' + item.id + ')">Edit</button>';
    h += '<button class="btn btn-danger btn-xs" onclick="deleteItemClick(' + item.id + ',\'' + en + '\')">Delete</button>';
    h += '</div></div>';
    return h;
}

function loadPopupDetails(item) {
    if (item.item_type === 'onu' && item.genieacs_device_id) {
        fetchAPI('?_route=plugin/genieacs_topology_api&action=get_device_detail&device_id=' + encodeURIComponent(item.genieacs_device_id), function(r) {
            if (r && r.success) {
                var d = r.device;
                var el = document.getElementById('onu-details-' + item.id);
                if (item.genieacs_device_id.indexOf('cust_') === 0) {
                    if (el) el.innerHTML = '<p><small>Customer: ' + (d.fullname || 'N/A') + '</small></p>';
                } else {
                    if (el) el.innerHTML = '<p><small>SN: ' + (d.serial_number || 'N/A') + '</small></p><p><small>IP: ' + (d.ip_tr069 || 'N/A') + '</small></p><p><small>RX: ' + (d.rx_power || 'N/A') + ' dBm</small></p>';
                }
            }
        });
    }
    if (item.item_type === 'server') {
        loadServerChain(item);
    }
    if (item.item_type === 'odp') {
        loadODPPorts(item);
    }
}

function loadServerChain(item) {
    var el = document.getElementById('server-chain-' + item.id);
    if (!el) return;
    var cfg = item.config || {};
    var props = item.properties || {};
    var h = '';
    if (props.isp_link) h += '<p><small>ISP: ' + props.isp_link + '</small></p>';
    if (props.mikrotik_device_id) h += '<p><small>MikroTik: ' + props.mikrotik_device_id.substring(0,12) + '...</small></p>';
    if (props.olt_link) h += '<p><small>OLT: ' + props.olt_link + '</small></p>';
    var ponPorts = cfg.pon_ports || {};
    if (Object.keys(ponPorts).length > 0) {
        h += '<p><small><strong>PON Ports:</strong></small></p>';
        var sorted = Object.keys(ponPorts).sort(function(a,b){return parseInt(a)-parseInt(b);});
        sorted.forEach(function(k) { h += '<p><small>PON ' + k + ': ' + ponPorts[k] + ' dBm</small></p>'; });
    }
    if (!h) h = '<small>No connections configured</small>';
    el.innerHTML = h;
}

function loadODPPorts(item) {
    var el = document.getElementById('odp-ports-' + item.id);
    if (!el) return;
    var cfg = item.config || {};
    var rx = cfg.port_rx_power || {};
    var pc = parseInt(cfg.port_count) || 8;
    var inputPower = parseFloat(cfg.input_power);
    var h = '';
    for (var i = 1; i <= pc; i++) {
        var measured = rx[i] ? rx[i] + ' dBm' : null;
        var calculated = null;
        if (!isNaN(inputPower)) {
            var splitterLoss = 10 * Math.log10(pc) / Math.LN10;
            calculated = Math.round((inputPower - splitterLoss) * 100) / 100;
        }
        var display = measured || (calculated !== null ? calculated + ' dBm (est)' : 'empty');
        h += '<p><small>Port ' + i + ': ' + display + '</small></p>';
    }
    el.innerHTML = h;
}

function updateCounters() {
    var c = { server:0, olt:0, odc:0, odp:0, onu:0, switch:0, htb:0 };
    allMapItems.forEach(function(i) { if (c[i.item_type] !== undefined) c[i.item_type]++; });
    document.getElementById('server-count').textContent = c.server;
    document.getElementById('olt-count').textContent = c.olt;
    document.getElementById('odc-count').textContent = c.odc;
    document.getElementById('odp-count').textContent = c.odp;
    document.getElementById('onu-count').textContent = c.onu;
    document.getElementById('switch-count').textContent = c.switch;
    document.getElementById('htb-count').textContent = c.htb;
}

function refreshMap(cb) {
    fetchAPI('?_route=plugin/genieacs_topology_api&action=get_items', function(r) {
        if (r && r.success) { loadMap(r.items); }
        if (cb) cb();
    });
}

function fetchAPI(url, cb) {
    $.ajax({
        url: url,
        method: 'GET',
        dataType: 'json',
        success: function(r) { cb(r); },
        error: function() { cb(null); }
    });
}

function updateItemPosition(id, lat, lng) {
    $.ajax({
        url: '?_route=plugin/genieacs_topology_api&action=update_position',
        method: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ item_id: id, latitude: lat, longitude: lng }),
        dataType: 'json'
    });
}

function manageServerLinks(id) {
    var item = allMapItems.find(function(i) { return i.id == id; });
    if (!item) return;
    var f = document.getElementById('form-server-links');
    f.item_id.value = id;
    var p = item.properties || {};
    f.isp_link.value = p.isp_link || '';
    f.mikrotik_device_id.value = p.mikrotik_device_id || '';
    f.olt_link.value = p.olt_link || '';
    var ponPorts = (item.config && item.config.pon_ports) || {};
    var cnt = Object.keys(ponPorts).length || 0;
    var td = '<td style="width:140px;padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">';
    var td2 = '</label></td><td style="padding:4px 0">';
    var html = '<h6 style="margin:0 0 4px 0">PON Output Power</h6>';
    for (var i = 1; i <= Math.max(cnt, 4); i++) {
        html += '<table style="width:100%"><tr>' + td + 'Port ' + i + td2 + '<input type="number" step="0.01" name="pon_port_' + i + '_power" class="form-control" value="' + (ponPorts[i] || '2.00') + '"></td></tr></table>';
    }
    document.getElementById('pon-output-power-container').innerHTML = html;
    $('#serverLinksModal').modal('show');
}

function saveServerLinks() {
    var f = document.getElementById('form-server-links');
    var data = { item_id: f.item_id.value };
    data.isp_link = f.isp_link.value;
    data.mikrotik_device_id = f.mikrotik_device_id.value;
    data.olt_link = f.olt_link.value;
    for (var i = 1; i <= 16; i++) {
        var inp = document.querySelector('[name="pon_port_' + i + '_power"]');
        if (inp) data['pon_port_' + i + '_power'] = inp.value;
    }
    $.ajax({
        url: '?_route=plugin/genieacs_topology_api&action=update_server_links',
        method: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(data),
        dataType: 'json',
        success: function(r) {
            if (r && r.success) { $('#serverLinksModal').modal('hide'); refreshMap(); showToast('Server links updated', 'success'); }
            else { showToast('Failed to update', 'danger'); }
        },
        error: function() { showToast('Failed to update', 'danger'); }
    });
}

function showItemList(type) {
    var items = allMapItems.filter(function(i) { return i.item_type === type; });
    var title = type.toUpperCase() + ' List';
    document.getElementById('itemListModalTitle').textContent = title;
    var c = document.getElementById('item-list-container');
    if (items.length === 0) { c.innerHTML = '<p>No items found</p>'; }
    else {
        var h = '<div class="list-group">';
        items.forEach(function(i) {
            var sb = i.status === 'online' ? '🟢' : i.status === 'offline' ? '🔴' : '⚪';
            h += '<a href="#" class="list-group-item list-group-item-action" onclick="zoomToItem(' + i.id + ',\'' + type + '\');return false"><strong>' + sb + ' ' + i.name + '</strong> <small class="text-muted">' + parseFloat(i.latitude).toFixed(4) + ', ' + parseFloat(i.longitude).toFixed(4) + '</small></a>';
        });
        h += '</div>';
        c.innerHTML = h;
    }
    $('#itemListModal').modal('show');
}

function zoomToItem(id, type) {
    var item = allMapItems.find(function(i) { return i.id == id && i.item_type === type; });
    if (!item) return;
    $('#itemListModal').modal('hide');
    map.flyTo([parseFloat(item.latitude), parseFloat(item.longitude)], 17, { duration: 1.5 });
    setTimeout(function() { if (markers[item.id]) markers[item.id].openPopup(); }, 1600);
}

function showAddItemModal() {
    if (!locationPointer) {
        var center = map.getCenter();
        locationPointer = L.marker(center, { draggable: true }).addTo(map);
        locationPointer.on('dragend', function(ev) {
            updateFormCoords(ev.target.getLatLng());
        });
        updateFormCoords(center);
    } else {
        updateFormCoords(locationPointer.getLatLng());
    }
    $('#addItemModal').modal('show');
}

function updateItemForm(type) {
    var df = document.getElementById('dynamic-fields');
    df.innerHTML = '<div class="text-center"><i class="glyphicon glyphicon-refresh glyphicon-spin"></i> Loading...</div>';

    var td = '<td style="width:140px;padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">';
    var td2 = '</label></td><td style="padding:4px 0">';
    function row(html) { return '<table style="width:100%"><tr>' + html + '</tr></table>'; }
    function field(label, input) { return row(td + label + td2 + input + '</td>'); }

    var h = '';

    if (type === 'server') {
        h += field('Parent Server', '<select name="parent_id" class="form-control"><option value="">No Parent</option>' + serverOnlyOptions() + '</select>');
        h += field('ISP Link', '<input type="text" name="isp_link" class="form-control" placeholder="e.g. 10.0.0.1">');
        h += field('MikroTik Device', '<input type="text" name="mikrotik_device_id" class="form-control" placeholder="GenieACS device ID">');
        h += field('OLT Link', '<input type="text" name="olt_link" class="form-control" placeholder="e.g. 10.0.0.2">');
        h += field('PON Ports Count', '<input type="number" id="pon_port_count" name="pon_port_count" class="form-control" value="0" min="0" max="16" onchange="generatePonFields(this.value)">');
        h += '<div id="pon-output-power-container"></div>';
        df.innerHTML = h;

    } else if (type === 'olt') {
        h += field('Parent Server', '<select name="parent_id" class="form-control"><option value="">No Parent</option>' + serverOptions() + '</select>');
        h += row(td + 'Output Power (dBm)' + td2 + '<input type="number" step="0.01" name="output_power" class="form-control" value="2.00">' + '</td>' + td + 'PON Port Count' + td2 + '<input type="number" name="pon_count" class="form-control" value="1" min="1" max="16" onchange="generateOltPonFields(this.value)">' + '</td>');
        h += row(td + 'Attenuation (dB)' + td2 + '<input type="number" step="0.01" name="attenuation_db" class="form-control" value="0">' + '</td>' + td + 'OLT Link' + td2 + '<input type="text" name="olt_link" class="form-control" placeholder="e.g. 10.0.0.2">' + '</td>');
        h += '<div id="olt-pon-power-container"></div>';
        df.innerHTML = h;

    } else if (type === 'odc') {
        h += field('Parent PON Port', '<select name="olt_pon_port_id" class="form-control" required><option value="">Select PON Port</option></select>');
        h += field('Port Count', '<input type="number" name="port_count" class="form-control" value="4">');
        df.innerHTML = h;
        $.get('?_route=plugin/genieacs_topology_api&action=get_pon_ports', function(r) {
            if (r && r.success) {
                var sel = document.querySelector('[name="olt_pon_port_id"]');
                var opt = '<option value="">Select PON Port</option>';
                var avail = 0, used = 0;
                r.ports.forEach(function(p) {
                    if (p.is_used) { used++; opt += '<option value="' + p.id + '" disabled>' + p.olt_name + ' - PON ' + p.pon_number + ' (Used by ' + p.connected_odc_name + ')</option>'; }
                    else { avail++; opt += '<option value="' + p.id + '">' + p.olt_name + ' - PON ' + p.pon_number + ' (' + p.output_power + ' dBm)</option>'; }
                });
                sel.innerHTML = opt;
                if (avail === 0 && r.ports.length > 0 && used > 0) df.innerHTML = '<div class="alert alert-warning">All PON ports are used</div>' + df.innerHTML;
                else if (r.ports.length === 0) df.innerHTML = '<div class="alert alert-warning">No PON ports found. Add OLT with PON ports first.</div>' + df.innerHTML;
            }
        });

    } else if (type === 'odp') {
        h += field('Parent (ODC/ODP)', '<select name="parent_id" id="odp-parent-select" class="form-control" required onchange="loadODPPortOptions(this.value)"><option value="">Select Parent</option>' + odcOptions() + '</select>');
        h += '<div class="form-group" id="odc-port-group" style="display:none;margin-bottom:0"><table style="width:100%"><tr>' + td + 'ODC Port' + td2 + '<select name="odc_port" class="form-control"><option value="">Select port</option></select></td></tr></table></div>';
        h += row(td + 'Port Count' + td2 + '<select name="port_count" class="form-control"><option value="4">4 Port / 1:4</option><option value="8" selected>8 Port / 1:8</option><option value="16">16 Port / 1:16</option></select>' + '</td>' + td + 'Use Splitter' + td2 + '<select name="use_splitter" class="form-control" onchange="toggleSplitter(this.value)"><option value="0">No</option><option value="1">Yes</option></select>' + '</td>');
        h += '<div id="splitter-group" style="display:none">' + field('Splitter Ratio', '<select name="splitter_ratio" class="form-control"><option value="1:2">1:2</option><option value="1:4">1:4</option><option value="1:8" selected>1:8</option><option value="1:16">1:16</option><option value="1:32">1:32</option><option value="20:80">20:80</option><option value="30:70">30:70</option><option value="50:50">50:50</option></select>') + '</div>';
        df.innerHTML = h;

    } else if (type === 'onu') {
        h += field('Customer Name', '<input type="text" name="customer_name" class="form-control" required>');
        h += field('GenieACS Device', '<select name="genieacs_device_id" class="form-control" required onchange="onOnuDeviceChange(this)"><option value="">Select device</option></select>');
        h += row(td + 'Parent' + td2 + '<select name="parent_id" class="form-control" required onchange="onOnuParentChange(this)"><option value="">Select Parent</option></select>' + '</td>' + td + 'ODP Port' + td2 + '<select name="odp_port" class="form-control" style="display:none"><option value="">Select ODP first</option></select>' + '</td>');
        df.innerHTML = h;
        $.get('?_route=plugin/genieacs_topology_api&action=get_available_devices', function(r) {
            if (r && r.success) {
                var sel = document.querySelector('[name="genieacs_device_id"]');
                var custGroup = '<optgroup label="Customers">';
                var devGroup = '<optgroup label="GenieACS Devices">';
                r.devices.forEach(function(d) {
                    var label = d.is_customer ? d.serial_number + ' (' + d.pppoe_username + ')' : d.serial_number + ' (' + d.pppoe_username + ', ' + d.status + ')';
                    if (d.is_customer) {
                        custGroup += '<option value="' + d.device_id + '" data-is-customer="1">' + label + '</option>';
                    } else {
                        devGroup += '<option value="' + d.device_id + '">' + label + '</option>';
                    }
                });
                custGroup += '</optgroup>';
                devGroup += '</optgroup>';
                sel.innerHTML += custGroup + devGroup;
            }
        });
        $.get('?_route=plugin/genieacs_topology_api&action=get_parents', function(r) {
            if (r && r.success) {
                var sel = document.querySelector('[name="parent_id"]');
                var groups = {};
                r.items.forEach(function(it) {
                    var t = it.item_type.charAt(0).toUpperCase() + it.item_type.slice(1);
                    if (!groups[t]) groups[t] = '';
                    var label = it.name;
                    if (it.port_count !== undefined) {
                        var avail = it.port_count - it.used_count;
                        label += ' (' + avail + '/' + it.port_count + ' available)';
                    }
                    groups[t] += '<option value="' + it.id + '" data-type="' + it.item_type + '">' + label + '</option>';
                });
                var order = ['Odp', 'Switch', 'Htb'];
                order.forEach(function(g) {
                    if (groups[g]) { sel.innerHTML += '<optgroup label="' + g + '">' + groups[g] + '</optgroup>'; }
                });
            }
        });

    } else if (type === 'switch' || type === 'htb') {
        h += field('Customer Name', '<input type="text" name="customer_name" class="form-control">');
        h += field('Parent', '<select name="parent_id" class="form-control" required><option value="">Select Parent</option>' + allParentOptions() + '</select>');
        h += field('Port Count', '<input type="number" name="port_count" class="form-control" value="4" min="0" max="48">');
        df.innerHTML = h;

    } else {
        df.innerHTML = '';
    }
}

function serverOptions() {
    var h = '';
    allMapItems.forEach(function(i) { if (i.item_type === 'server') h += '<option value="' + i.id + '">' + i.name + '</option>'; });
    return h;
}

function serverOnlyOptions() {
    // For server-to-server parent selection
    var h = '';
    allMapItems.forEach(function(i) { if (i.item_type === 'server') h += '<option value="' + i.id + '">' + i.name + '</option>'; });
    return h;
}

function odcOptions() {
    var h = '<optgroup label="ODC">';
    allMapItems.forEach(function(i) {
        if (i.item_type === 'odc') h += '<option value="' + i.id + '" data-type="odc">' + i.name + '</option>';
    });
    h += '</optgroup>';
    // Also add ODPs with custom ratio for cascading
    var addOdp = false;
    allMapItems.forEach(function(i) {
        if (i.item_type === 'odp' && i.config && i.config.splitter_ratio && ['20:80','30:70','50:50'].indexOf(i.config.splitter_ratio) >= 0) {
            if (!addOdp) { h += '<optgroup label="ODP (Cascading)">'; addOdp = true; }
            h += '<option value="' + i.id + '" data-type="odp">' + i.name + '</option>';
        }
    });
    if (addOdp) h += '</optgroup>';
    return h;
}

function allParentOptions() {
    var groups = {};
    allMapItems.forEach(function(i) {
        var t = i.item_type.charAt(0).toUpperCase() + i.item_type.slice(1);
        if (!groups[t]) groups[t] = '';
        groups[t] += '<option value="' + i.id + '">' + i.name + '</option>';
    });
    var h = '';
    var order = ['Server','Olt','Odc','Odp','Switch','Htb','Onu'];
    order.forEach(function(g) {
        if (groups[g]) { h += '<optgroup label="' + g + '">' + groups[g] + '</optgroup>'; }
    });
    return h;
}

function switchOptions() {
    var h = '<optgroup label="Switch/Hub">';
    allMapItems.forEach(function(i) {
        if (i.item_type === 'switch') h += '<option value="' + i.id + '" data-type="switch">' + i.name + '</option>';
    });
    h += '</optgroup>';
    var odp = allMapItems.filter(function(i) { return i.item_type === 'odp'; });
    if (odp.length) {
        h += '<optgroup label="ODP">';
        odp.forEach(function(i) { h += '<option value="' + i.id + '" data-type="odp">' + i.name + '</option>'; });
        h += '</optgroup>';
    }
    return h;
}

function loadODPPortOptions(parentId) {
    if (!parentId) return;
    var sel = document.querySelector('[name="odc_port"]');
    var parentItem = allMapItems.find(function(i) { return i.id == parentId; });
    if (parentItem && parentItem.item_type === 'odc') {
        document.getElementById('odc-port-group').style.display = 'block';
        $.get('?_route=plugin/genieacs_topology_api&action=get_used_ports&parent_id=' + parentId + '&parent_type=odc', function(r) {
            var used = (r && r.success) ? r.used_ports : [];
            var pc = (parentItem.config && parentItem.config.port_count) || 4;
            var h = '<option value="">Select port</option>';
            for (var i = 1; i <= pc; i++) {
                if (used.indexOf(i) >= 0) h += '<option value="' + i + '" disabled>Port ' + i + ' (Used)</option>';
                else h += '<option value="' + i + '">Port ' + i + '</option>';
            }
            sel.innerHTML = h;
        });
    } else {
        document.getElementById('odc-port-group').style.display = 'none';
    }
}

function onOnuParentChange(sel) {
    var odpPort = document.querySelector('[name="odp_port"]');
    var option = sel.options[sel.selectedIndex];
    var type = option ? option.getAttribute('data-type') : '';
    if (type === 'odp') {
        odpPort.style.display = 'block';
        $.get('?_route=plugin/genieacs_topology_api&action=get_odp_ports', function(r) {
            if (r && r.success) {
                var odp = r.odp_list.find(function(o) { return o.id == sel.value; });
                if (odp) {
                    odpPort.innerHTML = '<option value="">Select port</option>';
                    odp.available_ports.forEach(function(p) { odpPort.innerHTML += '<option value="' + p + '">Port ' + p + '</option>'; });
                }
            }
        });
    } else {
        odpPort.style.display = 'none';
        odpPort.value = '';
    }
}

function toggleSplitter(val) {
    document.getElementById('splitter-group').style.display = val === '1' ? 'block' : 'none';
}

function generatePonFields(count) {
    var c = document.getElementById('pon-output-power-container');
    c.innerHTML = '';
    for (var i = 1; i <= parseInt(count); i++) {
        c.innerHTML += '<div class="form-group"><label>Port ' + i + ' Power (dBm)</label><input type="number" step="0.01" name="pon_port_' + i + '_power" class="form-control" value="2.00"></div>';
    }
}

function generateOltPonFields(count) {
    var c = document.getElementById('olt-pon-power-container');
    c.innerHTML = '';
    var td = '<td style="width:140px;padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">';
    var td2 = '</label></td><td style="padding:4px 0">';
    for (var i = 1; i <= parseInt(count); i++) {
        c.innerHTML += '<table style="width:100%"><tr>' + td + 'Port ' + i + ' Power' + td2 + '<input type="number" step="0.01" name="pon_power_' + i + '" class="form-control" value="9.00"></td></tr></table>';
    }
}

function addItem() {
    var f = document.getElementById('form-add-item');
    var data = {};
    for (var i = 0; i < f.elements.length; i++) {
        var e = f.elements[i];
        if (e.name) data[e.name] = e.value;
    }
    $.ajax({
        url: '?_route=plugin/genieacs_topology_api&action=add_item',
        method: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(data),
        dataType: 'json',
        success: function(r) {
            if (r && r.success) {
                $('#addItemModal').modal('hide');
                if (locationPointer) { map.removeLayer(locationPointer); locationPointer = null; }
                refreshMap(function() {
                    map.flyTo([parseFloat(data.latitude) || 0, parseFloat(data.longitude) || 0], 17, { duration: 1 });
                });
                showToast('Item added', 'success');
            } else { showToast(r && r.message || 'Failed', 'danger'); }
        },
        error: function(xhr, status, error) {
            showToast('AJAX error: ' + status, 'danger');
        }
    });
}

function editItemClick(id) {
    $.get('?_route=plugin/genieacs_topology_api&action=get_item_detail&item_id=' + id, function(r) {
        if (r && r.success) {
            var item = r.item;
            var f = document.getElementById('form-edit-item');
            f.item_id.value = item.id;
            f.item_type.value = item.item_type.toUpperCase();
            f.name.value = item.name;
            f.latitude.value = item.latitude;
            f.longitude.value = item.longitude;
            var df = document.getElementById('edit-dynamic-fields');
            var td = '<td style="width:140px;padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">';
            var td2 = '</label></td><td style="padding:4px 0">';
            function r2(h) { return '<table style="width:100%"><tr>' + h + '</tr></table>'; }
            function f2(l, i) { return r2(td + l + td2 + i + '</td>'); }
            var h = '';
            var type = item.item_type;
            if (type === 'server') {
                h += f2('Parent Server', '<select name="parent_id" class="form-control"><option value="">No Parent</option>' + serverOnlyOptions() + '</select>');
                df.innerHTML = h;
                if (item.parent_id) { var sel = document.querySelector('[name="parent_id"]'); if (sel) sel.value = item.parent_id; }
            } else if (type === 'olt') {
                var cfg = item.config || {};
                h += f2('Parent Server', '<select name="parent_id" class="form-control"><option value="">No Parent</option>' + serverOptions() + '</select>');
                h += f2('Output Power', '<input type="number" step="0.01" name="output_power" class="form-control" value="' + (cfg.output_power || 2) + '">');
                h += f2('PON Port Count', '<input type="number" name="pon_count" class="form-control" value="' + (cfg.pon_count || 1) + '" min="1" max="16" onchange="editGenerateOltPonFields(this.value, ' + id + ')">');
                h += '<div id="edit-olt-pon-power-container"></div>';
                h += f2('Attenuation', '<input type="number" step="0.01" name="attenuation_db" class="form-control" value="' + (cfg.attenuation_db || 0) + '">');
                h += f2('OLT Link', '<input type="text" name="olt_link" class="form-control" value="' + (cfg.olt_link || '') + '">');
                df.innerHTML = h;
                // Fill parent
                if (item.parent_id) { var sel = document.querySelector('[name="parent_id"]'); if (sel) sel.value = item.parent_id; }
                editGenerateOltPonFields(cfg.pon_count || 1, id);
            } else if (type === 'odc') {
                var cfg = item.config || {};
                h += f2('Parent PON Port', '<select name="olt_pon_port_id" class="form-control"><option value="">Select PON Port</option></select>');
                h += f2('Port Count', '<input type="number" name="port_count" class="form-control" value="' + (cfg.port_count || 4) + '">');
                df.innerHTML = h;
                $.get('?_route=plugin/genieacs_topology_api&action=get_pon_ports', function(r2) {
                    if (r2 && r2.success) {
                        var sel = document.querySelector('[name="olt_pon_port_id"]');
                        var opt = '<option value="">Select PON Port</option>';
                        r2.ports.forEach(function(p) {
                            var selected = (p.id == cfg.olt_pon_port_id) ? ' selected' : '';
                            var disabled = p.is_used && (p.id != cfg.olt_pon_port_id) ? ' disabled' : '';
                            opt += '<option value="' + p.id + '"' + selected + disabled + '>' + p.olt_name + ' - PON ' + p.pon_number + ' (' + p.output_power + ' dBm)' + (p.is_used ? ' (Used)' : '') + '</option>';
                        });
                        sel.innerHTML = opt;
                    }
                });
            } else if (type === 'odp') {
                var cfg = item.config || {};
                var selParent = item.parent_id || '';
                h += f2('Parent (ODC/ODP)', '<select name="parent_id" id="edit-odp-parent-select" class="form-control" onchange="editLoadODPPortOptions(this.value)"><option value="">Select Parent</option>' + odcOptions() + '</select>');
                h += '<div id="edit-odc-port-group" style="display:' + (selParent && allMapItems.find(function(i){return i.id==selParent&&i.item_type==='odc'}) ? 'block' : 'none') + '">' + r2(td + 'ODC Port' + td2 + '<select name="odc_port" class="form-control"><option value="">Select port</option></select></td>') + '</div>';
                h += f2('Port Count', '<select name="port_count" class="form-control"><option value="4"' + (cfg.port_count==4?' selected':'') + '>4 Port / 1:4</option><option value="8"' + (cfg.port_count==8?' selected':'') + '>8 Port / 1:8</option><option value="16"' + (cfg.port_count==16?' selected':'') + '>16 Port / 1:16</option></select>');
                h += f2('Use Splitter', '<select name="use_splitter" class="form-control" onchange="editToggleSplitter(this.value)"><option value="0"' + (cfg.use_splitter==0?' selected':'') + '>No</option><option value="1"' + (cfg.use_splitter==1?' selected':'') + '>Yes</option></select>');
                h += '<div id="edit-splitter-group" style="display:' + (cfg.use_splitter==1?'block':'none') + '">' + f2('Splitter Ratio', '<select name="splitter_ratio" class="form-control"><option value="1:2"' + ((cfg.splitter_ratio||'')=='1:2'?' selected':'') + '>1:2</option><option value="1:4"' + ((cfg.splitter_ratio||'')=='1:4'?' selected':'') + '>1:4</option><option value="1:8"' + ((cfg.splitter_ratio||'')=='1:8'?' selected':'') + '>1:8</option><option value="1:16"' + ((cfg.splitter_ratio||'')=='1:16'?' selected':'') + '>1:16</option><option value="1:32"' + ((cfg.splitter_ratio||'')=='1:32'?' selected':'') + '>1:32</option><option value="20:80"' + ((cfg.splitter_ratio||'')=='20:80'?' selected':'') + '>20:80</option><option value="30:70"' + ((cfg.splitter_ratio||'')=='30:70'?' selected':'') + '>30:70</option><option value="50:50"' + ((cfg.splitter_ratio||'')=='50:50'?' selected':'') + '>50:50</option></select>') + '</div>';
                df.innerHTML = h;
                if (selParent) { var sel = document.querySelector('[name="parent_id"]'); if (sel) sel.value = selParent; }
                if (selParent && allMapItems.find(function(i){return i.id==selParent&&i.item_type==='odc'})) { editLoadODPPortOptions(selParent); }
            } else if (type === 'onu') {
                var cfg = item.config || {};
                h += f2('Customer Name', '<input type="text" name="customer_name" class="form-control" value="' + (cfg.customer_name || '') + '">');
                h += r2(td + 'GenieACS Device' + td2 + '<select name="genieacs_device_id" class="form-control" onchange="onOnuDeviceChange(this)"><option value="">' + (item.genieacs_device_id || 'Select device') + '</option></select>' + '</td>');
                h += r2(td + 'Parent' + td2 + '<select name="parent_id" class="form-control" onchange="editOnuParentChange(this)"><option value="">Select Parent</option></select>' + '</td>' + td + 'ODP Port' + td2 + '<select name="odp_port" class="form-control" style="display:none"><option value="">Select ODP first</option></select>' + '</td>');
                df.innerHTML = h;
                // Load devices
                $.get('?_route=plugin/genieacs_topology_api&action=get_available_devices', function(r2) {
                    if (r2 && r2.success) {
                        var sel = document.querySelector('[name="genieacs_device_id"]');
                        var curId = item.genieacs_device_id || '';
                        var custGroup = '<optgroup label="Customers">';
                        var devGroup = '<optgroup label="GenieACS Devices">';
                        r2.devices.forEach(function(d) {
                            var label = d.is_customer ? d.serial_number + ' (' + d.pppoe_username + ')' : d.serial_number + ' (' + d.pppoe_username + ', ' + d.status + ')';
                            var selected = (d.device_id === curId) ? ' selected' : '';
                            if (d.is_customer) custGroup += '<option value="' + d.device_id + '" data-is-customer="1"' + selected + '>' + label + '</option>';
                            else devGroup += '<option value="' + d.device_id + '"' + selected + '>' + label + '</option>';
                        });
                        custGroup += '</optgroup>'; devGroup += '</optgroup>';
                        sel.innerHTML += custGroup + devGroup;
                    }
                });
                // Load parents
                $.get('?_route=plugin/genieacs_topology_api&action=get_parents', function(r2) {
                    if (r2 && r2.success) {
                        var sel = document.querySelector('[name="parent_id"]');
                        var groups = {};
                        r2.items.forEach(function(it) {
                            var t = it.item_type.charAt(0).toUpperCase() + it.item_type.slice(1);
                            if (!groups[t]) groups[t] = '';
                            var label = it.name;
                            if (it.port_count !== undefined) {
                                var avail = it.port_count - it.used_count;
                                label += ' (' + avail + '/' + it.port_count + ' available)';
                            }
                            groups[t] += '<option value="' + it.id + '" data-type="' + it.item_type + '">' + label + '</option>';
                        });
                        var order = ['Odp', 'Switch', 'Htb'];
                        order.forEach(function(g) {
                            if (groups[g]) { sel.innerHTML += '<optgroup label="' + g + '">' + groups[g] + '</optgroup>'; }
                        });
                        if (item.parent_id) { sel.value = item.parent_id; editOnuParentChange(sel); }
                    }
                });
            } else if (type === 'switch' || type === 'htb') {
                var cfg = item.config || {};
                h += f2('Customer Name', '<input type="text" name="customer_name" class="form-control" value="' + (cfg.customer_name || '') + '">');
                h += f2('Parent', '<select name="parent_id" class="form-control"><option value="">Select Parent</option>' + allParentOptions() + '</select>');
                h += f2('Port Count', '<input type="number" name="port_count" class="form-control" value="' + (cfg.port_count || 4) + '" min="0" max="48">');
                df.innerHTML = h;
                if (item.parent_id) { var sel = document.querySelector('[name="parent_id"]'); if (sel) sel.value = item.parent_id; }
            } else {
                df.innerHTML = '';
            }
            $('#editItemModal').modal('show');
        }
    });
}

function editGenerateOltPonFields(count, itemId) {
    var item = allMapItems.find(function(i) { return i.id == itemId; });
    var cfg = item && item.config || {};
    var ponPorts = cfg.pon_ports || {};
    var c = document.getElementById('edit-olt-pon-power-container');
    c.innerHTML = '';
    var td = '<td style="width:140px;padding:4px 8px 4px 0;vertical-align:middle;white-space:nowrap"><label style="margin:0">';
    var td2 = '</label></td><td style="padding:4px 0">';
    for (var i = 1; i <= parseInt(count); i++) {
        var val = ponPorts[i] || '9.00';
        c.innerHTML += '<table style="width:100%"><tr>' + td + 'Port ' + i + ' Power' + td2 + '<input type="number" step="0.01" name="pon_power_' + i + '" class="form-control" value="' + val + '"></td></tr></table>';
    }
}

function editLoadODPPortOptions(parentId) {
    if (!parentId) return;
    var sel = document.querySelector('[name="odc_port"]');
    var parentItem = allMapItems.find(function(i) { return i.id == parentId; });
    if (parentItem && parentItem.item_type === 'odc') {
        document.getElementById('edit-odc-port-group').style.display = 'block';
        $.get('?_route=plugin/genieacs_topology_api&action=get_used_ports&parent_id=' + parentId + '&parent_type=odc', function(r) {
            var used = (r && r.success) ? r.used_ports : [];
            var pc = (parentItem.config && parentItem.config.port_count) || 4;
            var h = '<option value="">Select port</option>';
            for (var i = 1; i <= pc; i++) {
                if (used.indexOf(i) >= 0) h += '<option value="' + i + '" disabled>Port ' + i + ' (Used)</option>';
                else h += '<option value="' + i + '">Port ' + i + '</option>';
            }
            sel.innerHTML = h;
            // Preselect current value from item
            var curItem = allMapItems.find(function(it) { return it.id == parentId; });
            // Load current odp config
            $.get('?_route=plugin/genieacs_topology_api&action=get_item_detail&item_id=' + parentId, function(r2) {
                if (r2 && r2.success && r2.item && r2.item.config) {
                    sel.value = r2.item.config.odc_port || '';
                }
            });
        });
    } else {
        document.getElementById('edit-odc-port-group').style.display = 'none';
    }
}

function editToggleSplitter(val) {
    document.getElementById('edit-splitter-group').style.display = val === '1' ? 'block' : 'none';
}

function editOnuParentChange(sel) {
    var odpPort = document.querySelector('[name="odp_port"]');
    var option = sel.options[sel.selectedIndex];
    var type = option ? option.getAttribute('data-type') : '';
    if (type === 'odp') {
        odpPort.style.display = 'block';
        $.get('?_route=plugin/genieacs_topology_api&action=get_odp_ports', function(r) {
            if (r && r.success) {
                var odp = r.odp_list.find(function(o) { return o.id == sel.value; });
                if (odp) {
                    odpPort.innerHTML = '<option value="">Select port</option>';
                    odp.available_ports.forEach(function(p) { odpPort.innerHTML += '<option value="' + p + '">Port ' + p + '</option>'; });
                    // Try to preselect current odp_port
                    var curItem = allMapItems.find(function(i) { return i.id == sel.value; });
                }
            }
        });
    } else {
        odpPort.style.display = 'none';
        odpPort.value = '';
    }
}

function updateItem() {
    var f = document.getElementById('form-edit-item');
    var data = {};
    for (var i = 0; i < f.elements.length; i++) {
        var e = f.elements[i];
        if (e.name) data[e.name] = e.value;
    }
    $.ajax({
        url: '?_route=plugin/genieacs_topology_api&action=update_item',
        method: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(data),
        dataType: 'json',
        success: function(r) {
            if (r && r.success) { $('#editItemModal').modal('hide'); refreshMap(); showToast('Item updated', 'success'); }
            else { showToast(r && r.message || 'Failed to update', 'danger'); }
        },
        error: function(xhr, status, error) {
            showToast('AJAX error: ' + status, 'danger');
        }
    });
}

function deleteItemClick(id, name) {
    if (!confirm('Delete "' + name + '"? All children will also be deleted!')) return;
    $.ajax({
        url: '?_route=plugin/genieacs_topology_api&action=delete_item',
        method: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ item_id: id }),
        dataType: 'json',
        success: function(r) {
            if (r && r.success) { refreshMap(); showToast('Item deleted', 'success'); }
            else { showToast('Failed to delete', 'danger'); }
        },
        error: function() { showToast('Failed to delete', 'danger'); }
    });
}

function onOnuDeviceChange(sel) {
    var opt = sel.options[sel.selectedIndex];
    if (opt && opt.getAttribute('data-is-customer')) {
        // Auto-fill customer name from customer option
        document.querySelector('[name="customer_name"]').value = opt.text.split(' (')[0];
    }
}

function showToast(msg, type) {
    var t = document.createElement('div');
    t.className = 'alert alert-' + (type === 'success' ? 'success' : type === 'danger' ? 'danger' : 'info');
    t.style.cssText = 'position:fixed;top:20px;right:20px;z-index:19999;min-width:250px';
    t.textContent = msg;
    document.body.appendChild(t);
    setTimeout(function() { t.remove(); }, 3000);
}
{/literal}
</script>
{include file="sections/footer.tpl"}
