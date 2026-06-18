import React, { useState, useEffect } from 'react';
import {
  View, Text, TouchableOpacity, ScrollView,
  Image, StyleSheet, Alert, ActivityIndicator,
  TextInput, Platform
} from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import * as Clipboard from 'expo-clipboard';

const HEAT_CHART = [
  { min: 54, max: 999, flag: 'Red 🔴', risk: 'Extreme Danger', workRest: '---', water: 'Stop all work', color: '#d32f2f', textColor: '#fff' },
  { min: 50, max: 53, flag: 'Red 🔴', risk: 'Extreme Danger', workRest: '20:10', water: '1 cup every 10 min', color: '#d32f2f', textColor: '#fff' },
  { min: 39, max: 49, flag: 'Orange 🟠', risk: 'Danger', workRest: '30:10', water: '1 cup every 15 min', color: '#f57c00', textColor: '#fff' },
  { min: 32, max: 38, flag: 'Yellow 🟡', risk: 'Extreme Caution', workRest: '40:10', water: '1 cup every 20 min', color: '#f9a825', textColor: '#000' },
  { min: 27, max: 31, flag: 'Green 🟢', risk: 'Caution', workRest: '50:10', water: '1 cup every 20 min', color: '#388e3c', textColor: '#fff' },
];

function getHeatLevel(hi) {
  return HEAT_CHART.find(r => hi >= r.min && hi <= r.max) || null;
}

function getQatarTime() {
  const now = new Date();
  const qatar = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Qatar' }));
  const h = qatar.getHours(), m = qatar.getMinutes();
  const ampm = h >= 12 ? 'PM' : 'AM';
  const hh = h % 12 || 12;
  const mm = String(m).padStart(2, '0');
  const dd = String(qatar.getDate()).padStart(2, '0');
  const mo = String(qatar.getMonth() + 1).padStart(2, '0');
  const yyyy = qatar.getFullYear();
  return { time: `${hh}:${mm} ${ampm}`, date: `${dd}/${mo}/${yyyy}` };
}

export default function App() {
  const [tab, setTab] = useState('report');
  const [image, setImage] = useState(null);
  const [imageBase64, setImageBase64] = useState(null);
  const [location, setLocation] = useState('Corridor F area 1');
  const [locations] = useState(['Corridor F area 1', 'Main Gate', 'Workshop A']);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [history, setHistory] = useState([]);
  const [copied, setCopied] = useState(false);

  async function takePhoto() {
    const perm = await ImagePicker.requestCameraPermissionsAsync();
    if (!perm.granted) { Alert.alert('Permission needed', 'Camera permission required'); return; }
    const res = await ImagePicker.launchCameraAsync({ base64: true, quality: 0.8 });
    if (!res.canceled) {
      setImage(res.assets[0].uri);
      setImageBase64(res.assets[0].base64);
      setResult(null);
    }
  }

  async function pickImage() {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) { Alert.alert('Permission needed', 'Gallery permission required'); return; }
    const res = await ImagePicker.launchImageLibraryAsync({ base64: true, quality: 0.8 });
    if (!res.canceled) {
      setImage(res.assets[0].uri);
      setImageBase64(res.assets[0].base64);
      setResult(null);
    }
  }

  async function generateReport() {
    if (!imageBase64) { Alert.alert('No image', 'Please take or upload a photo first.'); return; }
    if (!location) { Alert.alert('No location', 'Please enter a location.'); return; }
    setLoading(true);
    setResult(null);
    try {
      const { time, date } = getQatarTime();
      const resp = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'claude-sonnet-4-6',
          max_tokens: 1000,
          messages: [{
            role: 'user',
            content: [
              { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: imageBase64 } },
              { type: 'text', text: 'Extract temperature (°C), humidity (%), and heat index (°C) from this meter image. Respond ONLY with JSON: {"temperature": <number>, "humidity": <number>, "heatIndex": <number>}' }
            ]
          }]
        })
      });
      const data = await resp.json();
      let raw = data.content?.map(b => b.text || '').join('') || '';
      raw = raw.replace(/```json|```/g, '').trim();
      const parsed = JSON.parse(raw);
      const { temperature: temp, humidity, heatIndex: hi } = parsed;
      const level = getHeatLevel(hi);
      const isStop = hi >= 54;
      const report = `*Company* : MEDGULF\n*Location* : ${location}\n*Time* : ${time}\n*Date* : ${date}\n*Temp* : ${temp}°C\n*Humidity* : ${humidity}%\n*Heat Index* : ${hi}°C\n*Flag Colour* : ${level?.flag || 'Red 🔴'}\n*Risk* : ${level?.risk || 'Extreme Danger'}\n*Work/Rest* : ${isStop ? 'Stop all work' : level?.workRest}\n*Water Consumption* : ${isStop ? 'Stop all work' : level?.water}`;
      const entry = { temp, humidity, hi, level, location, time, date, report };
      setResult(entry);
      setHistory(h => [entry, ...h].slice(0, 50));
    } catch (e) {
      Alert.alert('Error', 'Could not read meter. Try a clearer image.');
    }
    setLoading(false);
  }

  async function copyReport() {
    if (!result) return;
    await Clipboard.setStringAsync(result.report);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <View style={s.root}>
      {/* Header */}
      <View style={s.header}>
        <Text style={s.headerIcon}>🌡️</Text>
        <View>
          <Text style={s.headerTitle}>Heat Stress Monitor</Text>
          <Text style={s.headerSub}>🛡️ MEDGULF HSE Dashboard</Text>
        </View>
      </View>

      {/* Tabs */}
      <View style={s.tabs}>
        {[['report','📋 Report'],['dashboard','📊 Dashboard'],['history','🗂️ History']].map(([k,l]) => (
          <TouchableOpacity key={k} style={[s.tab, tab===k && s.tabActive]} onPress={() => setTab(k)}>
            <Text style={[s.tabText, tab===k && s.tabTextActive]}>{l}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <ScrollView style={s.scroll} contentContainerStyle={{ padding: 16 }}>
        {tab === 'report' && (
          <>
            {/* Image Card */}
            <View style={s.card}>
              <Text style={s.cardTitle}>📷 Meter Image</Text>
              {image ? (
                <>
                  <Image source={{ uri: image }} style={s.preview} resizeMode="contain" />
                  <View style={{ flexDirection: 'row', gap: 8, marginTop: 10 }}>
                    <TouchableOpacity style={[s.btn, { flex: 1, backgroundColor: '#e8eaf6' }]} onPress={takePhoto}>
                      <Text style={[s.btnText, { color: '#1a2a5e' }]}>📷 Retake</Text>
                    </TouchableOpacity>
                    <TouchableOpacity style={[s.btn, { flex: 1, backgroundColor: '#e8eaf6' }]} onPress={pickImage}>
                      <Text style={[s.btnText, { color: '#1a2a5e' }]}>🔄 Change</Text>
                    </TouchableOpacity>
                  </View>
                </>
              ) : (
                <View style={s.uploadBox}>
                  <Text style={{ fontSize: 40, marginBottom: 8 }}>🖼️</Text>
                  <Text style={s.uploadText}>Take a photo or upload an image{'\n'}of the temperature/humidity meter</Text>
                  <View style={{ flexDirection: 'row', gap: 10, marginTop: 14 }}>
                    <TouchableOpacity style={[s.btn, { flex: 1 }]} onPress={takePhoto}>
                      <Text style={s.btnText}>📷 Take Photo</Text>
                    </TouchableOpacity>
                    <TouchableOpacity style={[s.btn, s.btnOutline, { flex: 1 }]} onPress={pickImage}>
                      <Text style={[s.btnText, { color: '#1a2a5e' }]}>⬆️ Upload</Text>
                    </TouchableOpacity>
                  </View>
                </View>
              )}
            </View>

            {/* Location */}
            <View style={s.card}>
              <Text style={s.cardTitle}>📍 Location</Text>
              <TextInput
                value={location}
                onChangeText={setLocation}
                placeholder="Enter location"
                style={s.input}
              />
              <Text style={{ fontSize: 12, color: '#888', marginTop: 6 }}>Quick select:</Text>
              <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 6 }}>
                {locations.map(l => (
                  <TouchableOpacity key={l} onPress={() => setLocation(l)}
                    style={[s.chip, location === l && s.chipActive]}>
                    <Text style={[s.chipText, location === l && s.chipTextActive]}>{l}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <TouchableOpacity style={[s.btn, s.btnFull, loading && { backgroundColor: '#9eaac7' }]}
              onPress={generateReport} disabled={loading}>
              {loading ? <ActivityIndicator color="#fff" /> : <Text style={s.btnText}>⚡ Generate Report</Text>}
            </TouchableOpacity>

            {result && (
              <View style={s.card}>
                <View style={[s.flagBanner, { backgroundColor: result.level?.color }]}>
                  <Text style={[s.flagText, { color: result.level?.textColor }]}>
                    {result.level?.flag}  {result.level?.risk}
                  </Text>
                </View>
                <View style={s.metricsRow}>
                  {[['🌡️', `${result.temp}°C`, 'Temp'], ['💧', `${result.humidity}%`, 'Humidity'], ['🔥', `${result.hi}°C`, 'Heat Index']].map(([icon, val, lbl]) => (
                    <View key={lbl} style={s.metric}>
                      <Text style={{ fontSize: 22 }}>{icon}</Text>
                      <Text style={s.metricVal}>{val}</Text>
                      <Text style={s.metricLbl}>{lbl}</Text>
                    </View>
                  ))}
                </View>
                <View style={s.infoBox}>
                  <Text style={s.reportText}>{result.report}</Text>
                </View>
                <TouchableOpacity style={[s.btn, s.btnFull, copied && { backgroundColor: '#388e3c' }]} onPress={copyReport}>
                  <Text style={s.btnText}>{copied ? '✅ Copied!' : '📋 Copy Report'}</Text>
                </TouchableOpacity>
              </View>
            )}
          </>
        )}

        {tab === 'dashboard' && (
          <>
            <Text style={s.sectionTitle}>📊 Recent Readings</Text>
            {history.length === 0 && <Text style={s.empty}>No data yet. Generate a report first.</Text>}
            {history.slice(0, 10).map((d, i) => (
              <View key={i} style={[s.card, { borderLeftWidth: 4, borderLeftColor: d.level?.color }]}>
                <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
                  <Text style={{ fontWeight: '700' }}>{d.location}</Text>
                  <View style={[s.badge, { backgroundColor: d.level?.color }]}>
                    <Text style={[s.badgeText, { color: d.level?.textColor }]}>{d.level?.risk}</Text>
                  </View>
                </View>
                <Text style={s.metaText}>🌡️ {d.temp}°C  💧 {d.humidity}%  🔥 HI: {d.hi}°C</Text>
                <Text style={s.metaText}>{d.date} {d.time}</Text>
              </View>
            ))}
            <Text style={[s.sectionTitle, { marginTop: 8 }]}>📋 Heat Index Reference</Text>
            {[
              { range: '27–31°C', flag: 'Green 🟢', risk: 'Caution', wr: '50:10', water: '1 cup/20 min', bg: '#e8f5e9', border: '#388e3c' },
              { range: '32–38°C', flag: 'Yellow 🟡', risk: 'Extreme Caution', wr: '40:10', water: '1 cup/20 min', bg: '#fffde7', border: '#f9a825' },
              { range: '39–49°C', flag: 'Orange 🟠', risk: 'Danger', wr: '30:10', water: '1 cup/15 min', bg: '#fff3e0', border: '#f57c00' },
              { range: '50–53°C', flag: 'Red 🔴', risk: 'Extreme Danger', wr: '20:10', water: '1 cup/10 min', bg: '#ffebee', border: '#d32f2f' },
              { range: '54°C+', flag: 'Red 🔴', risk: 'Stop Work', wr: '—', water: 'Stop all work', bg: '#ffcdd2', border: '#b71c1c' },
            ].map((r, i) => (
              <View key={i} style={[s.refRow, { backgroundColor: r.bg, borderLeftColor: r.border }]}>
                <Text style={s.refRange}>{r.range}  {r.flag}</Text>
                <Text style={s.refDetail}>{r.risk} | {r.wr} | {r.water}</Text>
              </View>
            ))}
          </>
        )}

        {tab === 'history' && (
          <>
            <Text style={s.sectionTitle}>🗂️ All Reports</Text>
            {history.length === 0 && <Text style={s.empty}>No history yet.</Text>}
            {history.map((d, i) => (
              <View key={i} style={s.card}>
                <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
                  <Text style={{ fontWeight: '700', fontSize: 13 }}>{d.location}</Text>
                  <View style={[s.badge, { backgroundColor: d.level?.color }]}>
                    <Text style={[s.badgeText, { color: d.level?.textColor }]}>{d.level?.flag}</Text>
                  </View>
                </View>
                <Text style={s.metaText}>{d.date} {d.time}</Text>
                <Text style={s.metaText}>🌡️ {d.temp}°C  💧 {d.humidity}%  🔥 {d.hi}°C</Text>
              </View>
            ))}
          </>
        )}
      </ScrollView>
    </View>
  );
}

const s = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#f0f2f5' },
  header: { backgroundColor: '#1a2a5e', padding: 16, flexDirection: 'row', alignItems: 'center', gap: 12, paddingTop: Platform.OS === 'android' ? 40 : 50 },
  headerIcon: { fontSize: 32, marginRight: 4 },
  headerTitle: { color: '#fff', fontSize: 18, fontWeight: '700' },
  headerSub: { color: '#aac4ff', fontSize: 12 },
  tabs: { flexDirection: 'row', backgroundColor: '#fff', borderBottomWidth: 1, borderBottomColor: '#e0e0e0' },
  tab: { flex: 1, paddingVertical: 12, alignItems: 'center', borderBottomWidth: 3, borderBottomColor: 'transparent' },
  tabActive: { borderBottomColor: '#1a2a5e' },
  tabText: { fontSize: 12, color: '#888' },
  tabTextActive: { color: '#1a2a5e', fontWeight: '700' },
  scroll: { flex: 1 },
  card: { backgroundColor: '#fff', borderRadius: 16, padding: 16, marginBottom: 14, shadowColor: '#000', shadowOpacity: 0.06, shadowRadius: 6, elevation: 2 },
  cardTitle: { fontWeight: '700', fontSize: 15, marginBottom: 12 },
  uploadBox: { borderWidth: 2, borderColor: '#c0c8e0', borderStyle: 'dashed', borderRadius: 12, padding: 24, alignItems: 'center' },
  uploadText: { color: '#888', fontSize: 13, textAlign: 'center' },
  preview: { width: '100%', height: 200, borderRadius: 10, backgroundColor: '#f5f5f5' },
  btn: { backgroundColor: '#1a2a5e', borderRadius: 10, padding: 12, alignItems: 'center' },
  btnOutline: { backgroundColor: '#fff', borderWidth: 2, borderColor: '#1a2a5e' },
  btnFull: { width: '100%', marginBottom: 14, padding: 14 },
  btnText: { color: '#fff', fontWeight: '700', fontSize: 14 },
  input: { borderWidth: 1, borderColor: '#d0d7e8', borderRadius: 10, padding: 10, fontSize: 14, marginBottom: 4 },
  chip: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20, backgroundColor: '#f0f2f5', borderWidth: 1, borderColor: '#d0d7e8' },
  chipActive: { backgroundColor: '#1a2a5e', borderColor: '#1a2a5e' },
  chipText: { fontSize: 12, color: '#555' },
  chipTextActive: { color: '#fff', fontWeight: '700' },
  flagBanner: { borderRadius: 10, padding: 12, alignItems: 'center', marginBottom: 12 },
  flagText: { fontWeight: '700', fontSize: 18 },
  metricsRow: { flexDirection: 'row', gap: 8, marginBottom: 12 },
  metric: { flex: 1, backgroundColor: '#f7f9ff', borderRadius: 10, padding: 10, alignItems: 'center' },
  metricVal: { fontWeight: '700', fontSize: 16 },
  metricLbl: { color: '#888', fontSize: 11 },
  infoBox: { backgroundColor: '#1a2a5e', borderRadius: 10, padding: 12, marginBottom: 12 },
  reportText: { color: '#e8f0fe', fontSize: 12, lineHeight: 20 },
  sectionTitle: { fontWeight: '700', fontSize: 16, marginBottom: 10 },
  empty: { textAlign: 'center', color: '#888', padding: 40 },
  badge: { borderRadius: 20, paddingHorizontal: 10, paddingVertical: 2 },
  badgeText: { fontSize: 11, fontWeight: '600' },
  metaText: { fontSize: 12, color: '#666', marginTop: 3 },
  refRow: { borderLeftWidth: 4, padding: 10, marginBottom: 2, borderRadius: 4 },
  refRange: { fontWeight: '700', fontSize: 13 },
  refDetail: { fontSize: 12, color: '#555', marginTop: 2 },
});