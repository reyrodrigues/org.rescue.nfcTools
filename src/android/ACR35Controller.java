package org.rescue.nfcTools;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;


import com.acs.audiojack.AesTrackData;
import com.acs.audiojack.AudioJackReader;
import com.acs.audiojack.DukptReceiver;
import com.acs.audiojack.DukptTrackData;
import com.acs.audiojack.Result;
import com.acs.audiojack.Status;
import com.acs.audiojack.Track1Data;
import com.acs.audiojack.Track2Data;
import com.acs.audiojack.TrackData;

import android.util.Log;

import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager.NameNotFoundException;
import android.media.AudioManager;
import android.os.Bundle;
import android.preference.CheckBoxPreference;
import android.preference.EditTextPreference;
import android.preference.ListPreference;
import android.preference.Preference;
import android.preference.PreferenceActivity;
import android.text.InputType;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.EditText;
import android.widget.Toast;

import android.nfc.*;

import org.apache.cordova.*;

import java.io.UnsupportedEncodingException;
import java.util.Timer;
import java.util.TimerTask;

import java.util.Calendar;
import java.util.List;
import java.util.*;
import java.lang.StringBuffer;
import java.lang.System;
import java.io.*;

public class ACR35Controller extends CordovaPlugin {
    private AudioJackReader reader;
    private final String TAG = "MYAPP";
    private AudioManager am = null;
    private Timer timer = null;
    public boolean timedOut = false;
    private CallbackContext callbackContext;

    public ACR35Controller() {

    }

    @Override

    public void initialize(final CordovaInterface cordova, final CordovaWebView webView) {
        super.initialize(cordova, webView);

        am = (AudioManager) cordova.getActivity().getSystemService(Context.AUDIO_SERVICE);
        reader = new AudioJackReader(am, true);

        IntentFilter filter = new IntentFilter();
        filter.addAction(Intent.ACTION_HEADSET_PLUG);
        cordova.getActivity().registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {

                if (intent.getAction().equals(Intent.ACTION_HEADSET_PLUG)) {

                    boolean plugged = (intent.getIntExtra("state", 0) == 1);

                /* Mute the audio output if the reader is unplugged. */
                    reader.setMute(!plugged);
                }
            }
        }, filter);

        final StringBuffer buffer = new StringBuffer();
        final StringBuffer atrBuffer = new StringBuffer();


        reader.setOnPiccAtrAvailableListener(new AudioJackReader.OnPiccAtrAvailableListener() {
            @Override
            public void onPiccAtrAvailable(AudioJackReader audioJackReader, byte[] bytes) {
                Log.w(TAG, bytesToHex(bytes));

                atrBuffer.append(bytesToHex(bytes));
            }
        });

        reader.setOnPiccResponseApduAvailableListener(new AudioJackReader.OnPiccResponseApduAvailableListener() {
            @Override
            public void onPiccResponseApduAvailable(AudioJackReader audioJackReader, byte[] bytes) {
                byte[] resultBytes = new byte[bytes.length - 2];
                byte[] statusBytes = new byte[2];

                System.arraycopy(bytes, 0, resultBytes, 0, bytes.length - 2);
                System.arraycopy(bytes, bytes.length - 2, statusBytes, 0, 2);

                Log.w(TAG, bytesToHex(statusBytes));

                buffer.append(bytesToHex(resultBytes));
                buffer.append("");

            }
        });

        reader.setOnResultAvailableListener(new AudioJackReader.OnResultAvailableListener() {
            @Override
            public void onResultAvailable(AudioJackReader audioJackReader, Result result) {
                //reader.sleep();
                timer.cancel();

                final String stringResult = buffer.toString();
                final String atrResult = atrBuffer.toString();

                cordova.getActivity().runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        if(timedOut) {
                            PluginResult dataResult = new PluginResult(PluginResult.Status.OK,  "TIMEDOUT");
                            callbackContext.sendPluginResult(dataResult);
                        } else {
                            JSONArray resultArray = new JSONArray();
                            resultArray.put(stringResult.replaceAll("\\s", ""));
                            resultArray.put(atrResult.replaceAll("\\s", ""));

                            PluginResult dataResult = new PluginResult(PluginResult.Status.OK,  resultArray);
                            callbackContext.sendPluginResult(dataResult);
                        }
                    }
                });
                buffer.delete(0, buffer.length());
                atrBuffer.delete(0, atrBuffer.length());
            }
        });
    }

    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {
        am.setStreamVolume(AudioManager.STREAM_MUSIC, am.getStreamMaxVolume(AudioManager.STREAM_MUSIC), 0);
        this.callbackContext = callbackContext;
        timedOut = false;

        Log.w(TAG, action);

        final String loadKeyCommand = "FF 82 00 00 06 %s";
        final String authCommand = "FF 86 00 00 05 01 00 %s 60 00";
        final String defaultKey = "FF FF FF FF FF FF";
        String authKeyCommand = "FF 86 00 00 05 01 00 00 60 00";

        if(action.equals("readIdFromTag")) {
            executeAPDUCommands(new byte[][]{
                    hexToBytes("FFCA000000")
            });
        }
        if (action.equals("readDataFromTag")) {
            executeAPDUCommands(new byte[][]{
                    hexToBytes(String.format(loadKeyCommand, defaultKey)),
                    hexToBytes(String.format(authCommand, "04")),
                    hexToBytes("FF B0 00 04 10"),
                    hexToBytes("FF B0 00 05 10"),
                    hexToBytes("FF B0 00 06 10"),
                    hexToBytes(String.format(authCommand, "08")),
                    hexToBytes("FF B0 00 08 10"),
                    hexToBytes("FF B0 00 09 10"),
                    hexToBytes("FF B0 00 0A 10"),
                    hexToBytes(String.format(authCommand, "10")),
                    hexToBytes("FF B0 00 10 10"),
                    hexToBytes("FF B0 00 11 10")
            });
        }
        if (action.equals("writeDataIntoTag")) {
            try {
                String dataString = data.get(0).toString();
                byte[] dataToWrite = new byte[128];
                Arrays.fill(dataToWrite, (byte)0);
                byte[] dataBytes = hexToBytes(dataString);
                System.arraycopy(dataBytes, 0, dataToWrite, 0, dataBytes.length);

                String dataStringToWrite = bytesToHex(dataToWrite).replaceAll("\\s","");
                String commandString1 = "FF D6 00 04 30"+ dataStringToWrite.substring(0, 95);
                String commandString2 = "FF D6 00 08 30"+ dataStringToWrite.substring(96, (96*2)-1);
                String commandString3 = "FF D6 00 10 20"+ dataStringToWrite.substring(96*2, (96*2+64)-1);

                Log.w(TAG, dataStringToWrite);
                executeAPDUCommands(new byte[][]{
                        hexToBytes(String.format(loadKeyCommand, defaultKey)),
                        hexToBytes(String.format(authCommand, "04")),
                        hexToBytes(commandString1),
                        hexToBytes(String.format(authCommand, "08")),
                        hexToBytes(commandString2),
                        hexToBytes(String.format(authCommand, "10")),
                        hexToBytes(commandString3),
                });
            } catch (java.lang.Exception e) {
                Log.w(TAG, e);
            }
        }

        PluginResult dataResult = new PluginResult(PluginResult.Status.OK, "IGNORE");
        dataResult.setKeepCallback(true);

        callbackContext.sendPluginResult(dataResult);
        return true;
    }


    private void executeAPDUCommands(final byte[][] commands) {
        final ACR35Controller self = this;
        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                reader.setMute(false);
                reader.start();

                reader.reset(new AudioJackReader.OnResetCompleteListener() {
                    @Override
                    public void onResetComplete(AudioJackReader audioJackReader) {

                        if (!reader.piccPowerOn(10, 0x8F))
                            Log.w(TAG, "Error");
                        for (byte[] command: commands) {
                            reader.piccTransmit(10, command);
                        }

                        reader.piccPowerOff();

                    }
                });
                Calendar calendar = Calendar.getInstance(); // gets a calendar using the default time zone and locale.
                calendar.add(Calendar.SECOND, 15);

                timer = new Timer();
                timer.schedule(new TimeoutClass(reader, self), calendar.getTime());
            }
        });
    }

    final protected static char[] hexArray = "0123456789ABCDEF".toCharArray();

    public static String bytesToHex(byte[] bytes) {
        char[] hexChars = new char[bytes.length * 2];
        for (int j = 0; j < bytes.length; j++) {
            int v = bytes[j] & 0xFF;
            hexChars[j * 2] = hexArray[v >>> 4];
            hexChars[j * 2 + 1] = hexArray[v & 0x0F];
        }
        return new String(hexChars);
    }

    private byte[] hexToBytes(String hexString) {

        byte[] byteArray = null;
        int count = 0;
        char c = 0;
        int i = 0;

        boolean first = true;
        int length = 0;
        int value = 0;

        // Count number of hex characters
        for (i = 0; i < hexString.length(); i++) {

            c = hexString.charAt(i);
            if (c >= '0' && c <= '9' || c >= 'A' && c <= 'F' || c >= 'a'
                    && c <= 'f') {
                count++;
            }
        }

        byteArray = new byte[(count + 1) / 2];
        for (i = 0; i < hexString.length(); i++) {

            c = hexString.charAt(i);
            if (c >= '0' && c <= '9') {
                value = c - '0';
            } else if (c >= 'A' && c <= 'F') {
                value = c - 'A' + 10;
            } else if (c >= 'a' && c <= 'f') {
                value = c - 'a' + 10;
            } else {
                value = -1;
            }

            if (value >= 0) {

                if (first) {

                    byteArray[length] = (byte) (value << 4);

                } else {

                    byteArray[length] |= value;
                    length++;
                }

                first = !first;
            }
        }

        return byteArray;
    }

    private class TimeoutClass extends TimerTask {
        private ACR35Controller controller;
        private AudioJackReader reader;

        public TimeoutClass(AudioJackReader reader, ACR35Controller controller) {
            this.reader = reader;
            this.controller = controller;
        }

        @Override
        public void run() {
            Log.w("Timing out", "Timing out");
            this.controller.timedOut = true;

            PluginResult dataResult = new PluginResult(PluginResult.Status.OK,  "TIMEDOUT");
            callbackContext.sendPluginResult(dataResult);

            reader.reset(new AudioJackReader.OnResetCompleteListener() {
                @Override
                public void onResetComplete(AudioJackReader audioJackReader) {

                    //reader.sleep();
                }
            });
        }
    }
}
