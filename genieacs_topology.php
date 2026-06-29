<?php

/**
 * 
 * PHP Mikrotik Billing (https://github.com/hotspotbilling/phpnuxbill/)
 *
 * Network Map Toplogy Plugin for PHP Mikrotik Billing
 *
 * @author: Gerandonk Mods <noc@igrwifi.my.id>
 * Website: https://igrwifi.my.id/
 * GitHub: https://github.com/gerandonk/
 * Telegram: https://t.me/sklitinov/
 *
 **/

require_once 'genieacs.php';

register_menu("Network Map", true, "genieacs_topology", 'AFTER_PLANS', 'glyphicon glyphicon-globe', '', '', ['SuperAdmin', 'Admin']);

function genieacs_topology_create_tables()
{
    $t1 = ORM::for_table('map_items')->raw_query("SHOW TABLES LIKE 'map_items'")->find_one();
    if (!$t1) {
        ORM::raw_execute("
            CREATE TABLE IF NOT EXISTS `map_items` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `item_type` enum('server','olt','odc','odp','onu','switch','htb') NOT NULL,
                `parent_id` int(11) DEFAULT NULL,
                `name` varchar(255) NOT NULL,
                `latitude` decimal(10,8) NOT NULL,
                `longitude` decimal(11,8) NOT NULL,
                `genieacs_device_id` varchar(255) DEFAULT NULL,
                `status` enum('online','offline','unknown') DEFAULT 'unknown',
                `properties` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
                `created_at` timestamp NULL DEFAULT current_timestamp(),
                `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`),
                KEY `parent_id` (`parent_id`),
                KEY `idx_genieacs_device_id` (`genieacs_device_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    } else {
        // Migration: add new item types to ENUM for existing installations
        ORM::raw_execute("ALTER TABLE `map_items` CHANGE `item_type` `item_type` enum('server','olt','odc','odp','onu','switch','htb') NOT NULL");
    }
    $t2 = ORM::for_table('map_connections')->raw_query("SHOW TABLES LIKE 'map_connections'")->find_one();
    if (!$t2) {
        ORM::raw_execute("
            CREATE TABLE IF NOT EXISTS `map_connections` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `from_item_id` int(11) NOT NULL,
                `to_item_id` int(11) NOT NULL,
                `connection_type` enum('online','offline') DEFAULT 'online',
                `path_coordinates` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
                `created_at` timestamp NULL DEFAULT current_timestamp(),
                `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`),
                KEY `from_item_id` (`from_item_id`),
                KEY `to_item_id` (`to_item_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    }
    $t3 = ORM::for_table('server_pon_ports')->raw_query("SHOW TABLES LIKE 'server_pon_ports'")->find_one();
    if (!$t3) {
        ORM::raw_execute("
            CREATE TABLE IF NOT EXISTS `server_pon_ports` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `map_item_id` int(11) NOT NULL,
                `port_number` int(11) NOT NULL,
                `output_power` decimal(5,2) DEFAULT 2.00,
                `created_at` timestamp NULL DEFAULT current_timestamp(),
                `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`),
                UNIQUE KEY `unique_server_port` (`map_item_id`,`port_number`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    }
    $t4 = ORM::for_table('olt_config')->raw_query("SHOW TABLES LIKE 'olt_config'")->find_one();
    if (!$t4) {
        ORM::raw_execute("
            CREATE TABLE IF NOT EXISTS `olt_config` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `map_item_id` int(11) NOT NULL,
                `output_power` decimal(5,2) DEFAULT 2.00,
                `pon_count` int(11) DEFAULT 1,
                `attenuation_db` decimal(5,2) DEFAULT 0.00,
                `olt_link` varchar(255) DEFAULT NULL,
                `created_at` timestamp NULL DEFAULT current_timestamp(),
                `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`),
                KEY `map_item_id` (`map_item_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    }
    $t5 = ORM::for_table('olt_pon_ports')->raw_query("SHOW TABLES LIKE 'olt_pon_ports'")->find_one();
    if (!$t5) {
        ORM::raw_execute("
            CREATE TABLE IF NOT EXISTS `olt_pon_ports` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `olt_item_id` int(11) NOT NULL,
                `pon_number` int(11) NOT NULL,
                `output_power` decimal(5,2) DEFAULT 9.00,
                `created_at` timestamp NULL DEFAULT current_timestamp(),
                `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`),
                UNIQUE KEY `unique_olt_pon` (`olt_item_id`,`pon_number`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    }
    $t6 = ORM::for_table('odc_config')->raw_query("SHOW TABLES LIKE 'odc_config'")->find_one();
    if (!$t6) {
        ORM::raw_execute("
            CREATE TABLE IF NOT EXISTS `odc_config` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `map_item_id` int(11) NOT NULL,
                `olt_pon_port_id` int(11) DEFAULT NULL,
                `server_id` int(11) DEFAULT NULL,
                `server_pon_port` int(11) DEFAULT NULL,
                `port_count` int(11) NOT NULL,
                `parent_attenuation_db` decimal(5,2) DEFAULT 0.00,
                `calculated_power` decimal(5,2) DEFAULT NULL,
                `created_at` timestamp NULL DEFAULT current_timestamp(),
                `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`),
                KEY `map_item_id` (`map_item_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    }
    $t7 = ORM::for_table('odp_config')->raw_query("SHOW TABLES LIKE 'odp_config'")->find_one();
    if (!$t7) {
        ORM::raw_execute("
            CREATE TABLE IF NOT EXISTS `odp_config` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `map_item_id` int(11) NOT NULL,
                `odc_port` int(11) DEFAULT NULL,
                `input_power` decimal(5,2) DEFAULT NULL,
                `parent_odp_port` varchar(10) DEFAULT NULL,
                `port_count` int(11) NOT NULL,
                `use_splitter` tinyint(1) DEFAULT 0,
                `use_secondary_splitter` tinyint(1) DEFAULT 0,
                `secondary_splitter_ratio` varchar(20) DEFAULT NULL,
                `custom_secondary_ratio_output_port` varchar(10) DEFAULT NULL,
                `splitter_ratio` varchar(20) DEFAULT NULL,
                `custom_ratio_output_port` varchar(10) DEFAULT NULL,
                `calculated_power` decimal(5,2) DEFAULT NULL,
                `port_rx_power` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
                `created_at` timestamp NULL DEFAULT current_timestamp(),
                `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`),
                KEY `map_item_id` (`map_item_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    }
    $t8 = ORM::for_table('onu_config')->raw_query("SHOW TABLES LIKE 'onu_config'")->find_one();
    if (!$t8) {
        ORM::raw_execute("
            CREATE TABLE IF NOT EXISTS `onu_config` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `map_item_id` int(11) NOT NULL,
                `odp_port` int(11) DEFAULT NULL,
                `customer_name` varchar(255) DEFAULT NULL,
                `genieacs_device_id` varchar(255) DEFAULT NULL,
                `created_at` timestamp NULL DEFAULT current_timestamp(),
                `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`),
                UNIQUE KEY `genieacs_device_id` (`genieacs_device_id`),
                KEY `map_item_id` (`map_item_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    }
    $t9 = ORM::for_table('switch_config')->raw_query("SHOW TABLES LIKE 'switch_config'")->find_one();
    if (!$t9) {
        ORM::raw_execute("
            CREATE TABLE IF NOT EXISTS `switch_config` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `map_item_id` int(11) NOT NULL,
                `port_count` int(11) DEFAULT 4,
                `customer_name` varchar(255) DEFAULT NULL,
                `input_power` decimal(5,2) DEFAULT NULL,
                `created_at` timestamp NULL DEFAULT current_timestamp(),
                `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`),
                KEY `map_item_id` (`map_item_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    } else {
        // Migration: add customer_name to switch_config for existing installations
        try {
            ORM::raw_execute("ALTER TABLE `switch_config` ADD COLUMN `customer_name` varchar(255) DEFAULT NULL AFTER `port_count`");
        } catch (\Exception $e) {}
    }
    $t10 = ORM::for_table('htb_config')->raw_query("SHOW TABLES LIKE 'htb_config'")->find_one();
    if (!$t10) {
        ORM::raw_execute("
            CREATE TABLE IF NOT EXISTS `htb_config` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `map_item_id` int(11) NOT NULL,
                `port_count` int(11) DEFAULT 4,
                `customer_name` varchar(255) DEFAULT NULL,
                `input_power` decimal(5,2) DEFAULT NULL,
                `created_at` timestamp NULL DEFAULT current_timestamp(),
                `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`),
                KEY `map_item_id` (`map_item_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    } else {
        // Migration: add port_count to htb_config for existing installations
        try {
            ORM::raw_execute("ALTER TABLE `htb_config` ADD COLUMN `port_count` int(11) DEFAULT 4 AFTER `map_item_id`");
        } catch (\Exception $e) {
            // Column may already exist
        }
    }
}

function genieacs_topology_get_host()
{
    $hosts = json_decode(ORM::for_table('tbl_appconfig')->where('setting', 'genieacs_hosts')->find_one()->value ?? '[]', true);
    foreach ($hosts as $h) {
        if (!empty($h['active'])) {
            return $h;
        }
    }
    return count($hosts) > 0 ? $hosts[0] : null;
}

function genieacs_topology()
{
    global $ui, $admin;
    _admin();
    genieacs_topology_create_tables();

    $ui->assign('_title', 'Network Topology Map');
    $ui->assign('_system_menu', 'map');
    $ui->assign('_admin', $admin);

    $items = genieacs_topology_get_all_items();
    $ui->assign('items', json_encode($items));
    $ui->display('genieacs_topology.tpl');
}

function genieacs_topology_get_all_items()
{
    $rows = ORM::for_table('map_items')->order_by_asc('id')->find_array();
    $items = [];
    foreach ($rows as $row) {
        // Resolve parent_id from config for ODCs that were created without parent_id
        if (!$row['parent_id'] && $row['item_type'] === 'odc') {
            $cfg = ORM::for_table('odc_config')->where('map_item_id', $row['id'])->find_one();
            if ($cfg && $cfg->olt_pon_port_id) {
                $pp = ORM::for_table('olt_pon_ports')->find_one((int)$cfg->olt_pon_port_id);
                if ($pp) {
                    $row['parent_id'] = $pp->olt_item_id;
                } else {
                    $spp = ORM::for_table('server_pon_ports')->find_one((int)$cfg->olt_pon_port_id);
                    if ($spp) {
                        $row['parent_id'] = $spp->map_item_id;
                    }
                }
            }
        }
        $row['properties'] = json_decode($row['properties'] ?: '{}', true);
        $row['config'] = genieacs_topology_load_config($row);
        $row['status'] = genieacs_topology_calculate_status($row, $rows);
        $items[] = $row;
    }
    // Calculate RX powers (requires all items loaded)
    genieacs_topology_calculate_rx_powers($items);
    // Cascade offline
    foreach ($items as &$item) {
        if ($item['item_type'] === 'olt' && $item['status'] === 'offline') {
            genieacs_topology_cascade_offline($item['id'], $items);
        }
    }
    return $items;
}

function genieacs_topology_load_config($item)
{
    $id = $item['id'];
    switch ($item['item_type']) {
        case 'server':
            $ports = ORM::for_table('server_pon_ports')->where('map_item_id', $id)->order_by_asc('port_number')->find_array();
            $pon_ports = [];
            foreach ($ports as $p) {
                $pon_ports[$p['port_number']] = $p['output_power'];
            }
            return ['pon_ports' => $pon_ports];
        case 'olt':
            $cfg = ORM::for_table('olt_config')->where('map_item_id', $id)->find_one();
            return $cfg ? $cfg->as_array() : null;
        case 'odc':
            $cfg = ORM::for_table('odc_config')->where('map_item_id', $id)->find_one();
            return $cfg ? $cfg->as_array() : null;
        case 'odp':
            $cfg = ORM::for_table('odp_config')->where('map_item_id', $id)->find_one();
            if ($cfg) {
                $a = $cfg->as_array();
                if ($a['port_rx_power']) {
                    $a['port_rx_power'] = json_decode($a['port_rx_power'], true);
                }
                return $a;
            }
            return null;
        case 'onu':
            $cfg = ORM::for_table('onu_config')->where('map_item_id', $id)->find_one();
            return $cfg ? $cfg->as_array() : null;
        case 'switch':
            $cfg = ORM::for_table('switch_config')->where('map_item_id', $id)->find_one();
            return $cfg ? $cfg->as_array() : null;
        case 'htb':
            $cfg = ORM::for_table('htb_config')->where('map_item_id', $id)->find_one();
            return $cfg ? $cfg->as_array() : null;
    }
    return null;
}

function genieacs_topology_calculate_rx_powers(&$items)
{
    $itemsById = [];
    foreach ($items as &$it) { $itemsById[$it['id']] = &$it; }
    unset($it);

    foreach ($items as &$item) {
        if ($item['item_type'] === 'odc') {
            $cfg = $item['config'] ?: [];
            $ponPortId = $cfg['olt_pon_port_id'] ?? null;
            $parentPower = null;
            if ($ponPortId) {
                $pp = ORM::for_table('olt_pon_ports')->find_one((int)$ponPortId);
                if ($pp) $parentPower = (float)$pp->output_power;
                else {
                    $spp = ORM::for_table('server_pon_ports')->find_one((int)$ponPortId);
                    if ($spp) $parentPower = (float)$spp->output_power;
                }
            }
            $atten = (float)($cfg['parent_attenuation_db'] ?? 0);
            $calcPower = $parentPower !== null ? round($parentPower - $atten, 2) : null;
            if ($calcPower !== null) {
                $db = ORM::for_table('odc_config')->where('map_item_id', $item['id'])->find_one();
                if ($db) {
                    $db->calculated_power = $calcPower;
                    $db->save();
                }
                $item['config']['calculated_power'] = $calcPower;
            }
        }

        if ($item['item_type'] === 'odp') {
            $parentId = $item['parent_id'] ?? null;
            $inputPower = null;
            if ($parentId && isset($itemsById[$parentId])) {
                $parent = $itemsById[$parentId];
                if ($parent['item_type'] === 'odc') {
                    $inputPower = $parent['config']['calculated_power'] ?? null;
                } elseif ($parent['item_type'] === 'odp') {
                    $inputPower = $parent['config']['input_power'] ?? null;
                }
            }
            if ($inputPower !== null) {
                $db = ORM::for_table('odp_config')->where('map_item_id', $item['id'])->find_one();
                if ($db) {
                    $db->input_power = $inputPower;
                    $db->save();
                }
                $item['config']['input_power'] = $inputPower;
            }
        }

        // RX power for switch and htb is not calculated
    }
    unset($item);
}

function genieacs_topology_calculate_status(&$item, &$allItems)
{
    switch ($item['item_type']) {
        case 'server':
            $props = $item['properties'] ?: [];
            if (!empty($props['isp_link'])) return 'online';
            if (!empty($props['mikrotik_device_id'])) return 'online';
            if (!empty($props['olt_link'])) return 'online';
            return 'unknown';
        case 'olt':
            if (!empty($item['parent_id'])) {
                $p = genieacs_topology_find_item($item['parent_id'], $allItems);
                if ($p) {
                    $ps = genieacs_topology_calculate_status($p, $allItems);
                    if ($ps === 'offline') return 'offline';
                }
            }
            $cfg = $item['config'] ?: [];
            if (!empty($cfg['olt_link'])) return 'online';
            if (!empty($item['parent_id'])) return 'online';
            return 'unknown';
        case 'odc':
            $parentId = $item['parent_id'] ?? null;
            if (!$parentId) {
                $cfg = $item['config'] ?: [];
                if (!empty($cfg['olt_pon_port_id'])) {
                    $pp = ORM::for_table('olt_pon_ports')->find_one((int)$cfg['olt_pon_port_id']);
                    if ($pp) $parentId = $pp->olt_item_id;
                    else {
                        $spp = ORM::for_table('server_pon_ports')->find_one((int)$cfg['olt_pon_port_id']);
                        if ($spp) $parentId = $spp->map_item_id;
                    }
                }
            }
            if ($parentId) {
                $p = genieacs_topology_find_item($parentId, $allItems);
                if ($p) {
                    $ps = genieacs_topology_calculate_status($p, $allItems);
                    if ($ps === 'online') return 'online';
                    if ($ps === 'offline') return 'offline';
                }
            }
            return 'unknown';
        case 'odp':
            $p = genieacs_topology_find_item($item['parent_id'], $allItems);
            if ($p) {
                $ps = genieacs_topology_calculate_status($p, $allItems);
                if ($ps === 'online') return 'online';
                if ($ps === 'offline') return 'offline';
            }
            return 'unknown';
        case 'onu':
            if (!empty($item['parent_id'])) {
                $p = genieacs_topology_find_item($item['parent_id'], $allItems);
                if ($p) {
                    $ps = genieacs_topology_calculate_status($p, $allItems);
                    if ($ps === 'offline') return 'offline';
                }
            }
            $host = genieacs_topology_get_host();
            if (!empty($item['genieacs_device_id'])) {
                if (strpos($item['genieacs_device_id'], 'cust_') === 0) {
                    // Customer-linked ONU — inherit parent status
                    if (!empty($item['parent_id'])) {
                        $p = genieacs_topology_find_item($item['parent_id'], $allItems);
                        if ($p) {
                            $ps = genieacs_topology_calculate_status($p, $allItems);
                            if ($ps === 'online') return 'online';
                            if ($ps === 'offline') return 'offline';
                        }
                    }
                    return 'unknown';
                } elseif ($host) {
                    try {
                        $client = new GenieACSClient($host['host'], (int)$host['port'], $host['username'] ?? '', $host['password'] ?? '');
                        $result = $client->getDevice($item['genieacs_device_id']);
                        if ($result['success'] && $result['data']) {
                            $lastInform = $result['data']['_lastInform'] ?? null;
                            if ($lastInform) {
                                $diff = time() - strtotime($lastInform);
                                return ($diff < 300) ? 'online' : 'offline';
                            }
                        }
                    } catch (\Exception $e) {
                        // GenieACS unreachable — treat as unknown, not fatal
                    }
                }
            }
            return 'unknown';
        case 'switch':
        case 'htb':
            $p = genieacs_topology_find_item($item['parent_id'], $allItems);
            if ($p) {
                $ps = genieacs_topology_calculate_status($p, $allItems);
                if ($ps === 'offline') return 'offline';
            }
            return 'online'; // Infrastructure devices — assume online by default
    }
    return 'unknown';
}

function genieacs_topology_find_item($id, &$items)
{
    foreach ($items as &$i) {
        if ($i['id'] == $id) return $i;
    }
    return null;
}

function genieacs_topology_cascade_offline($parentId, &$items)
{
    foreach ($items as &$item) {
        if ($item['parent_id'] == $parentId) {
            $item['status'] = 'offline';
            genieacs_topology_cascade_offline($item['id'], $items);
        }
    }
}

// ============================================================
// API ENDPOINTS
// ============================================================

function genieacs_topology_api()
{
    _admin();
    genieacs_topology_create_tables();
    header('Content-Type: application/json');

    $action = _get('action', '');

    switch ($action) {
        case 'get_items':
            echo json_encode(['success' => true, 'items' => genieacs_topology_get_all_items()]);
            break;

        case 'get_item_detail':
            $id = (int)_get('item_id');
            $rows = ORM::for_table('map_items')->find_array();
            $found = null;
            foreach ($rows as $r) {
                if ($r['id'] == $id) {
                    $r['properties'] = json_decode($r['properties'] ?: '{}', true);
                    $r['config'] = genieacs_topology_load_config($r);
                    $found = $r;
                    break;
                }
            }
            echo json_encode(['success' => (bool)$found, 'item' => $found]);
            break;

        case 'get_waypoints':
            $conns = ORM::for_table('map_connections')->find_array();
            $result = [];
            foreach ($conns as $c) {
                $result[] = [
                    'from_item_id' => $c['from_item_id'],
                    'to_item_id' => $c['to_item_id'],
                    'path_coordinates' => json_decode($c['path_coordinates'] ?: '[]', true),
                ];
            }
            echo json_encode(['success' => true, 'waypoints' => $result]);
            break;

        case 'get_device_detail':
            $device_id = _get('device_id', '');
            if (strpos($device_id, 'cust_') === 0) {
                $custId = (int)substr($device_id, 5);
                $cust = ORM::for_table('tbl_customers')->find_one($custId);
                if ($cust) {
                    echo json_encode(['success' => true, 'device' => [
                        'serial_number' => $cust['fullname'],
                        'ip_tr069' => '',
                        'rx_power' => 'N/A',
                        'fullname' => $cust['fullname'],
                    ]]);
                    break;
                }
            } else {
                $host = genieacs_topology_get_host();
                if ($host && $device_id) {
                    $client = new GenieACSClient($host['host'], (int)$host['port'], $host['username'] ?? '', $host['password'] ?? '');
                    $result = $client->getDevice($device_id);
                    if ($result['success'] && $result['data']) {
                        $d = $result['data'];
                        $info = genieacs_extract_device_info($d);
                        echo json_encode(['success' => true, 'device' => $info]);
                        break;
                    }
                }
            }
            echo json_encode(['success' => false, 'error' => 'Device not found']);
            break;

        case 'get_available_devices':
            $host = genieacs_topology_get_host();
            $devices = [];
            $used = ORM::for_table('onu_config')->select('genieacs_device_id')->find_array();
            $usedIds = array_column($used, 'genieacs_device_id');
            if ($host) {
                $client = new GenieACSClient($host['host'], (int)$host['port'], $host['username'] ?? '', $host['password'] ?? '');
                $result = $client->getDevices([], 500, 0);
                if ($result['success'] && $result['data']) {
                    foreach ($result['data'] as $d) {
                        if (!in_array($d['_id'], $usedIds)) {
                            $serial = $d['_deviceId']['_SerialNumber'] ?? null;
                            if (!$serial) {
                                $oui = $d['_deviceId']['_OUI'] ?? '';
                                $pc = $d['_deviceId']['_ProductClass'] ?? '';
                                $serial = ($oui || $pc) ? $oui . $pc : $d['_id'];
                            }
                            $pppoe = 'N/A';
                            for ($i = 1; $i <= 8; $i++) {
                                $u = $d['InternetGatewayDevice']['WANDevice']['1']['WANConnectionDevice'][$i]['WANPPPConnection']['1']['Username']['_value'] ?? null;
                                if ($u && $u !== '' && $u !== 'N/A') {
                                    $pppoe = $u;
                                    break;
                                }
                            }
                            $lastInform = $d['_lastInform'] ?? null;
                            $status = 'unknown';
                            if ($lastInform) {
                                $ts = strtotime($lastInform);
                                $status = ($ts !== false && (time() - $ts) < 300) ? 'online' : 'offline';
                            }
                            $devices[] = [
                                'device_id' => $d['_id'],
                                'serial_number' => $serial,
                                'pppoe_username' => $pppoe,
                                'status' => $status,
                                'is_customer' => false,
                            ];
                        }
                    }
                }
            }

            // Also add customers from tbl_customers
            $customers = ORM::for_table('tbl_customers')->find_array();
            foreach ($customers as $c) {
                $custId = 'cust_' . $c['id'];
                if (!in_array($custId, $usedIds)) {
                    $devices[] = [
                        'device_id' => $custId,
                        'serial_number' => $c['fullname'],
                        'pppoe_username' => $c['username'],
                        'status' => 'customer',
                        'is_customer' => true,
                    ];
                }
            }

            echo json_encode(['success' => true, 'devices' => $devices]);
            break;

        case 'get_devices':
            $host = genieacs_topology_get_host();
            $devices = [];
            if ($host) {
                $client = new GenieACSClient($host['host'], (int)$host['port'], $host['username'] ?? '', $host['password'] ?? '');
                $result = $client->getDevices([], 500, 0);
                if ($result['success'] && $result['data']) {
                    foreach ($result['data'] as $d) {
                        $info = genieacs_extract_device_info($d);
                        $serial = $d['_deviceId']['_SerialNumber'] ?? null;
                        if (!$serial) {
                            $oui = $d['_deviceId']['_OUI'] ?? '';
                            $pc = $d['_deviceId']['_ProductClass'] ?? '';
                            $serial = ($oui || $pc) ? $oui . $pc : $d['_id'];
                        }
                        $lastInform = $d['_lastInform'] ?? null;
                        $status = 'unknown';
                        if ($lastInform) {
                            $ts = strtotime($lastInform);
                            $status = ($ts !== false && (time() - $ts) < 300) ? 'online' : 'offline';
                        }
                        $devices[] = [
                            'device_id' => $d['_id'],
                            'serial_number' => $serial,
                            'status' => $status,
                            'ip_address' => $info['tr069_ip'],
                        ];
                    }
                }
            }
            echo json_encode(['success' => true, 'devices' => $devices]);
            break;

        case 'get_pon_ports':
            $portType = _get('type', 'all'); // 'olt', 'server', or 'all'
            $ports = [];

            if ($portType === 'server' || $portType === 'all') {
                $servers = ORM::for_table('map_items')->where('item_type', 'server')->find_array();
                foreach ($servers as $s) {
                    $ponPorts = ORM::for_table('server_pon_ports')->where('map_item_id', $s['id'])->find_array();
                    foreach ($ponPorts as $pp) {
                        $used = ORM::for_table('odc_config')->where('olt_pon_port_id', $pp['id'])->find_one();
                        $isUsed = (bool)$used;
                        $connectedOdcName = '';
                        if ($isUsed && $used) {
                            $odcItem = ORM::for_table('map_items')->find_one($used->map_item_id);
                            $connectedOdcName = $odcItem ? $odcItem->name : '';
                        }
                        $ports[] = [
                            'id' => $pp['id'],
                            'source_type' => 'server',
                            'olt_name' => $s['name'] . ' (Server)',
                            'pon_number' => $pp['port_number'],
                            'output_power' => $pp['output_power'],
                            'is_used' => $isUsed,
                            'connected_odc_name' => $connectedOdcName,
                        ];
                    }
                }
            }

            if ($portType === 'olt' || $portType === 'all') {
                $olts = ORM::for_table('map_items')->where('item_type', 'olt')->find_array();
                foreach ($olts as $o) {
                    $oltPorts = ORM::for_table('olt_pon_ports')->where('olt_item_id', $o['id'])->find_array();
                    foreach ($oltPorts as $pp) {
                        $used = ORM::for_table('odc_config')->where('olt_pon_port_id', $pp['id'])->find_one();
                        $isUsed = (bool)$used;
                        $connectedOdcName = '';
                        if ($isUsed && $used) {
                            $odcItem = ORM::for_table('map_items')->find_one($used->map_item_id);
                            $connectedOdcName = $odcItem ? $odcItem->name : '';
                        }
                        $ports[] = [
                            'id' => $pp['id'],
                            'source_type' => 'olt',
                            'olt_name' => $o['name'] . ' (OLT)',
                            'pon_number' => $pp['pon_number'],
                            'output_power' => $pp['output_power'],
                            'is_used' => $isUsed,
                            'connected_odc_name' => $connectedOdcName,
                        ];
                    }
                }
            }

            echo json_encode(['success' => true, 'ports' => $ports]);
            break;

        case 'get_odp_ports':
            $odps = ORM::for_table('map_items')->where('item_type', 'odp')->find_array();
            $odpList = [];
            foreach ($odps as $o) {
                $cfg = ORM::for_table('odp_config')->where('map_item_id', $o['id'])->find_one();
                $portRxPower = [];
                $usedCount = 0;
                $portCount = 8;
                if ($cfg) {
                    $portRxPower = json_decode($cfg->port_rx_power ?: '{}', true);
                    $portCount = (int)$cfg->port_count ?: 8;
                    $usedCount = count($portRxPower);
                }
                $available = [];
                for ($i = 1; $i <= $portCount; $i++) {
                    if (!isset($portRxPower[$i])) {
                        $available[] = $i;
                    }
                }
                $odpList[] = [
                    'id' => $o['id'],
                    'name' => $o['name'],
                    'status' => 'unknown',
                    'port_count' => $portCount,
                    'used_count' => $usedCount,
                    'available_ports' => $available,
                ];
            }
            echo json_encode(['success' => true, 'odp_list' => $odpList]);
            break;

        case 'get_parents':
            $types = ['odp', 'switch', 'htb'];
            $items = ORM::for_table('map_items')->where_in('item_type', $types)->find_array();
            $list = [];
            foreach ($items as $it) {
                $entry = [
                    'id' => $it['id'],
                    'name' => $it['name'],
                    'item_type' => $it['item_type'],
                ];
                if ($it['item_type'] === 'odp') {
                    $cfg = ORM::for_table('odp_config')->where('map_item_id', $it['id'])->find_one();
                    $portRxPower = [];
                    $portCount = 8;
                    if ($cfg) {
                        $portRxPower = json_decode($cfg->port_rx_power ?: '{}', true);
                        $portCount = (int)$cfg->port_count ?: 8;
                    }
                    $entry['port_count'] = $portCount;
                    $entry['used_count'] = count($portRxPower);
                } else {
                    $cfg = $it['item_type'] === 'switch'
                        ? ORM::for_table('switch_config')->where('map_item_id', $it['id'])->find_one()
                        : ORM::for_table('htb_config')->where('map_item_id', $it['id'])->find_one();
                    $portCount = $cfg ? (int)$cfg->port_count : 4;
                    $usedCount = ORM::for_table('map_items')->where('parent_id', $it['id'])->where('item_type', 'onu')->count();
                    $entry['port_count'] = $portCount;
                    $entry['used_count'] = $usedCount;
                }
                $list[] = $entry;
            }
            echo json_encode(['success' => true, 'items' => $list]);
            break;

        case 'get_used_ports':
            $parentId = (int)_get('parent_id');
            $parentType = _get('parent_type', '');
            $usedPorts = [];
            if ($parentType === 'odc') {
                $odps = ORM::for_table('map_items')->where('item_type', 'odp')->where('parent_id', $parentId)->find_array();
                foreach ($odps as $o) {
                    $cfg = ORM::for_table('odp_config')->where('map_item_id', $o['id'])->find_one();
                    if ($cfg && $cfg->odc_port) {
                        $usedPorts[] = (int)$cfg->odc_port;
                    }
                }
            } elseif ($parentType === 'odp') {
                $childOdps = ORM::for_table('map_items')->where('item_type', 'odp')->where('parent_id', $parentId)->find_array();
                foreach ($childOdps as $o) {
                    $cfg = ORM::for_table('odp_config')->where('map_item_id', $o['id'])->find_one();
                    if ($cfg && $cfg->parent_odp_port) {
                        $usedPorts[] = $cfg->parent_odp_port;
                    }
                }
            }
            echo json_encode(['success' => true, 'used_ports' => $usedPorts]);
            break;

        case 'add_item':
            $data = json_decode(file_get_contents('php://input'), true);
            if (!$data) {
                echo json_encode(['success' => false, 'message' => 'No data']);
                break;
            }
            $itemType = $data['item_type'] ?? '';
            $name = $data['name'] ?? '';
            $lat = (float)($data['latitude'] ?? 0);
            $lng = (float)($data['longitude'] ?? 0);
            $parentId = !empty($data['parent_id']) ? (int)$data['parent_id'] : null;

            if (!$itemType || !$name) {
                echo json_encode(['success' => false, 'message' => 'Missing required fields']);
                break;
            }

            $item = ORM::for_table('map_items')->create();
            $item->item_type = $itemType;
            $item->name = $name;
            $item->latitude = $lat;
            $item->longitude = $lng;
            $item->parent_id = $parentId;
            $item->genieacs_device_id = $data['genieacs_device_id'] ?? null;
            $item->status = 'unknown';

            // Properties for server
            $props = [];
            if ($itemType === 'server') {
                if (!empty($data['isp_link'])) $props['isp_link'] = $data['isp_link'];
                if (!empty($data['mikrotik_device_id'])) $props['mikrotik_device_id'] = $data['mikrotik_device_id'];
                if (!empty($data['olt_link'])) $props['olt_link'] = $data['olt_link'];
            }
            $item->properties = json_encode($props);
            $item->save();

            // Type-specific configs
            switch ($itemType) {
                case 'server':
                    $ponCount = (int)($data['pon_port_count'] ?? 0);
                    for ($i = 1; $i <= $ponCount; $i++) {
                        $pp = ORM::for_table('server_pon_ports')->create();
                        $pp->map_item_id = $item->id;
                        $pp->port_number = $i;
                        $pp->output_power = (float)($data["pon_port_{$i}_power"] ?? 2.00);
                        $pp->save();
                    }
                    // Create child ODCs
                    if (!empty($data['odc_items'])) {
                        foreach ($data['odc_items'] as $odcData) {
                            if (!empty($odcData['name'])) {
                                $odc = ORM::for_table('map_items')->create();
                                $odc->item_type = 'odc';
                                $odc->name = $odcData['name'];
                                $odc->latitude = $lat;
                                $odc->longitude = $lng;
                                $odc->parent_id = $item->id;
                                $odc->status = 'unknown';
                                $odc->properties = json_encode(['hidden_marker' => true]);
                                $odc->save();

                                $odcCfg = ORM::for_table('odc_config')->create();
                                $odcCfg->map_item_id = $odc->id;
                                $odcCfg->olt_pon_port_id = $odcData['pon_port'] ?? null;
                                $odcCfg->port_count = (int)($odcData['port_count'] ?? 4);
                                $odcCfg->server_pon_port = $odcData['pon_port'] ?? null;
                                $odcCfg->save();
                            }
                        }
                    }
                    break;

                case 'olt':
                    $cfg = ORM::for_table('olt_config')->create();
                    $cfg->map_item_id = $item->id;
                    $cfg->output_power = (float)($data['output_power'] ?? 2.00);
                    $cfg->pon_count = (int)($data['pon_count'] ?? 1);
                    $cfg->attenuation_db = (float)($data['attenuation_db'] ?? 0);
                    $cfg->olt_link = $data['olt_link'] ?? null;
                    $cfg->save();

                    // OLT PON ports
                    $ponCount = (int)($data['pon_count'] ?? 1);
                    for ($i = 1; $i <= $ponCount; $i++) {
                        $pp = ORM::for_table('olt_pon_ports')->create();
                        $pp->olt_item_id = $item->id;
                        $pp->pon_number = $i;
                        $pp->output_power = (float)($data["pon_power_{$i}"] ?? 9.00);
                        $pp->save();
                    }
                    break;

                case 'odc':
                    $ponPortId = $data['olt_pon_port_id'] ?? null;
                    $parentId = null;
                    $parentPower = null;
                    if ($ponPortId) {
                        // Check if it's an OLT PON port
                        $oltPp = ORM::for_table('olt_pon_ports')->find_one((int)$ponPortId);
                        if ($oltPp) {
                            $parentId = $oltPp->olt_item_id;
                            $parentPower = (float)$oltPp->output_power;
                        } else {
                            // Check if it's a server PON port
                            $srvPp = ORM::for_table('server_pon_ports')->find_one((int)$ponPortId);
                            if ($srvPp) {
                                $parentId = $srvPp->map_item_id;
                                $parentPower = (float)$srvPp->output_power;
                            }
                        }
                    }
                    $item->parent_id = $parentId;
                    $item->save();

                    $cfg = ORM::for_table('odc_config')->create();
                    $cfg->map_item_id = $item->id;
                    $cfg->olt_pon_port_id = $ponPortId;
                    $cfg->port_count = (int)($data['port_count'] ?? 4);
                    $cfg->server_pon_port = $ponPortId;
                    $cfg->calculated_power = $parentPower;
                    $cfg->save();
                    break;

                case 'odp':
                    $cfg = ORM::for_table('odp_config')->create();
                    $cfg->map_item_id = $item->id;
                    $cfg->odc_port = $data['odc_port'] ?? null;
                    $cfg->parent_odp_port = $data['parent_odp_port'] ?? null;
                    $cfg->port_count = (int)($data['port_count'] ?? 8);
                    $cfg->use_splitter = (int)($data['use_splitter'] ?? 0);
                    $cfg->splitter_ratio = $data['splitter_ratio'] ?? null;
                    $cfg->custom_ratio_output_port = $data['custom_ratio_output_port'] ?? null;
                    $cfg->save();
                    break;

                case 'onu':
                    $cfg = ORM::for_table('onu_config')->create();
                    $cfg->map_item_id = $item->id;
                    $cfg->odp_port = !empty($data['odp_port']) ? (int)$data['odp_port'] : null;
                    $cfg->customer_name = $data['customer_name'] ?? '';
                    $cfg->genieacs_device_id = $data['genieacs_device_id'] ?? null;
                    $cfg->save();

                    // Update ODP port_rx_power if parent is an ODP
                    if (!empty($data['parent_id']) && !empty($data['odp_port'])) {
                        $parentItem = ORM::for_table('map_items')->find_one((int)$data['parent_id']);
                        if ($parentItem && $parentItem->item_type === 'odp') {
                            $odpCfg = ORM::for_table('odp_config')->where('map_item_id', $parentItem->id)->find_one();
                            if ($odpCfg) {
                                $rx = json_decode($odpCfg->port_rx_power ?: '{}', true);
                                $rx[(int)$data['odp_port']] = '-25.00';
                                $odpCfg->port_rx_power = json_encode($rx);
                                $odpCfg->save();
                            }
                        }
                    }
                    break;
                case 'switch':
                    $cfg = ORM::for_table('switch_config')->create();
                    $cfg->map_item_id = $item->id;
                    $cfg->port_count = (int)($data['port_count'] ?? 4);
                    if (!empty($data['customer_name'])) $cfg->customer_name = $data['customer_name'];
                    $cfg->save();
                    break;
                case 'htb':
                    $cfg = ORM::for_table('htb_config')->create();
                    $cfg->map_item_id = $item->id;
                    $cfg->port_count = (int)($data['port_count'] ?? 4);
                    $cfg->customer_name = $data['customer_name'] ?? '';
                    $cfg->save();
                    break;
            }

            echo json_encode(['success' => true, 'item_id' => $item->id]);
            break;

        case 'update_item':
            $data = json_decode(file_get_contents('php://input'), true);
            if (!$data || empty($data['item_id'])) {
                echo json_encode(['success' => false, 'message' => 'No data']);
                break;
            }
            $id = (int)$data['item_id'];
            $item = ORM::for_table('map_items')->find_one($id);
            if (!$item) {
                echo json_encode(['success' => false, 'message' => 'Item not found']);
                break;
            }

            if (!empty($data['name'])) $item->name = $data['name'];
            if (!empty($data['latitude'])) $item->latitude = (float)$data['latitude'];
            if (!empty($data['longitude'])) $item->longitude = (float)$data['longitude'];
            $item->save();

            $itemType = $item->item_type;
            switch ($itemType) {
                case 'olt':
                    $cfg = ORM::for_table('olt_config')->where('map_item_id', $id)->find_one();
                    if ($cfg) {
                        if (isset($data['output_power'])) $cfg->output_power = (float)$data['output_power'];
                        if (isset($data['attenuation_db'])) $cfg->attenuation_db = (float)$data['attenuation_db'];
                        if (isset($data['olt_link'])) $cfg->olt_link = $data['olt_link'];
                        $cfg->save();
                    }
                    break;
                case 'odc':
                    $cfg = ORM::for_table('odc_config')->where('map_item_id', $id)->find_one();
                    if ($cfg) {
                        if (isset($data['port_count'])) $cfg->port_count = (int)$data['port_count'];
                        $cfg->save();
                    }
                    break;
                case 'odp':
                    $cfg = ORM::for_table('odp_config')->where('map_item_id', $id)->find_one();
                    if ($cfg) {
                        if (isset($data['odc_port'])) $cfg->odc_port = (int)$data['odc_port'];
                        if (isset($data['port_count'])) $cfg->port_count = (int)$data['port_count'];
                        if (isset($data['use_splitter'])) $cfg->use_splitter = (int)$data['use_splitter'];
                        if (isset($data['splitter_ratio'])) $cfg->splitter_ratio = $data['splitter_ratio'];
                        $cfg->save();
                    }
                    break;
                case 'onu':
                    $cfg = ORM::for_table('onu_config')->where('map_item_id', $id)->find_one();
                    if ($cfg) {
                        if (isset($data['customer_name'])) $cfg->customer_name = $data['customer_name'];
                        $cfg->save();
                    }
                    break;
                case 'switch':
                    $cfg = ORM::for_table('switch_config')->where('map_item_id', $id)->find_one();
                    if ($cfg) {
                        if (isset($data['port_count'])) $cfg->port_count = (int)$data['port_count'];
                        if (isset($data['customer_name'])) $cfg->customer_name = $data['customer_name'];
                        $cfg->save();
                    }
                    break;
                case 'htb':
                    $cfg = ORM::for_table('htb_config')->where('map_item_id', $id)->find_one();
                    if ($cfg) {
                        if (isset($data['port_count'])) $cfg->port_count = (int)$data['port_count'];
                        if (isset($data['customer_name'])) $cfg->customer_name = $data['customer_name'];
                        $cfg->save();
                    }
                    break;
            }

            echo json_encode(['success' => true]);
            break;

        case 'update_position':
            $data = json_decode(file_get_contents('php://input'), true);
            if ($data && !empty($data['item_id'])) {
                $item = ORM::for_table('map_items')->find_one((int)$data['item_id']);
                if ($item) {
                    $item->latitude = (float)$data['latitude'];
                    $item->longitude = (float)$data['longitude'];
                    $item->save();
                    echo json_encode(['success' => true]);
                    break;
                }
            }
            echo json_encode(['success' => false]);
            break;

        case 'update_server_links':
            $data = json_decode(file_get_contents('php://input'), true);
            if (!$data || empty($data['item_id'])) {
                echo json_encode(['success' => false, 'message' => 'No data']);
                break;
            }
            $item = ORM::for_table('map_items')->find_one((int)$data['item_id']);
            if (!$item) {
                echo json_encode(['success' => false, 'message' => 'Server not found']);
                break;
            }
            $props = json_decode($item->properties ?: '{}', true);
            $props['isp_link'] = $data['isp_link'] ?? '';
            $props['mikrotik_device_id'] = $data['mikrotik_device_id'] ?? '';
            $props['olt_link'] = $data['olt_link'] ?? '';
            $item->properties = json_encode($props);
            $item->save();

            // Update PON port powers
            for ($i = 1; $i <= 16; $i++) {
                $key = "pon_port_{$i}_power";
                if (isset($data[$key]) && $data[$key] !== '') {
                    $pp = ORM::for_table('server_pon_ports')->where('map_item_id', $item->id)->where('port_number', $i)->find_one();
                    if ($pp) {
                        $pp->output_power = (float)$data[$key];
                        $pp->save();
                    }
                }
            }

            echo json_encode(['success' => true]);
            break;

        case 'delete_item':
            $data = json_decode(file_get_contents('php://input'), true);
            if (!$data || empty($data['item_id'])) {
                echo json_encode(['success' => false, 'message' => 'No data']);
                break;
            }
            $id = (int)$data['item_id'];
            $deleted = genieacs_topology_delete_item_cascade($id);
            echo json_encode(['success' => true, 'deleted_items' => $deleted]);
            break;

        case 'save_waypoints':
            $data = json_decode(file_get_contents('php://input'), true);
            if (!$data || !isset($data['parent_id']) || !isset($data['child_id'])) {
                echo json_encode(['success' => false, 'message' => 'No data']);
                break;
            }
            $fromId = (int)$data['parent_id'];
            $toId = (int)$data['child_id'];
            $waypoints = $data['waypoints'] ?? [];
            $pathJson = json_encode($waypoints);

            $existing = ORM::for_table('map_connections')->where('from_item_id', $fromId)->where('to_item_id', $toId)->find_one();
            if ($existing) {
                if (empty($waypoints)) {
                    $existing->delete();
                } else {
                    $existing->path_coordinates = $pathJson;
                    $existing->save();
                }
            } elseif (!empty($waypoints)) {
                $conn = ORM::for_table('map_connections')->create();
                $conn->from_item_id = $fromId;
                $conn->to_item_id = $toId;
                $conn->path_coordinates = $pathJson;
                $conn->save();
            }
            echo json_encode(['success' => true]);
            break;

        default:
            echo json_encode(['success' => false, 'message' => 'Unknown action']);
    }
}

function genieacs_topology_delete_item_cascade($id)
{
    $deleted = [$id];

    // Free parent port before cascade (for ODP port_rx_power tracking)
    $item = ORM::for_table('map_items')->find_one($id);
    if ($item && $item->item_type === 'onu' && $item->parent_id) {
        $parentItem = ORM::for_table('map_items')->find_one($item->parent_id);
        if ($parentItem && $parentItem->item_type === 'odp') {
            $onuCfg = ORM::for_table('onu_config')->where('map_item_id', $id)->find_one();
            if ($onuCfg && $onuCfg->odp_port) {
                $odpCfg = ORM::for_table('odp_config')->where('map_item_id', $parentItem->id)->find_one();
                if ($odpCfg) {
                    $rx = json_decode($odpCfg->port_rx_power ?: '{}', true);
                    unset($rx[(int)$onuCfg->odp_port]);
                    $odpCfg->port_rx_power = json_encode($rx);
                    $odpCfg->save();
                }
            }
        }
    }

    $children = ORM::for_table('map_items')->where('parent_id', $id)->find_array();
    foreach ($children as $child) {
        $deleted = array_merge($deleted, genieacs_topology_delete_item_cascade($child['id']));
    }

    // Delete configs
    ORM::for_table('server_pon_ports')->where('map_item_id', $id)->delete_many();
    ORM::for_table('olt_config')->where('map_item_id', $id)->delete_many();
    ORM::for_table('olt_pon_ports')->where('olt_item_id', $id)->delete_many();
    ORM::for_table('odc_config')->where('map_item_id', $id)->delete_many();
    ORM::for_table('odp_config')->where('map_item_id', $id)->delete_many();
    ORM::for_table('onu_config')->where('map_item_id', $id)->delete_many();
    ORM::for_table('switch_config')->where('map_item_id', $id)->delete_many();
    ORM::for_table('htb_config')->where('map_item_id', $id)->delete_many();
    ORM::for_table('map_connections')->where_raw('(`from_item_id` = ? OR `to_item_id` = ?)', [$id, $id])->delete_many();

    ORM::for_table('map_items')->find_one($id)->delete();
    return $deleted;
}
