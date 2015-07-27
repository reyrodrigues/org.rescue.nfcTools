package org.rescue.nfcTools;

import org.apache.cordova.CordovaPlugin;

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
import android.nfc.tech.IsoDep;
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
import android.util.Log;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

import java.io.UnsupportedEncodingException;
import java.util.Timer;
import java.util.TimerTask;

import java.util.Calendar;
import java.util.List;
import java.util.*;
import java.lang.StringBuffer;
import java.lang.System;
import java.io.*;


public class IsoDepController extends CordovaPlugin {
    private static final String TAG = "IsoDepController";

    private static String parseResult(byte[] bytes) {
        StringBuffer buffer = new StringBuffer();
        byte[] resultBytes = new byte[bytes.length - 2];
        byte[] statusBytes = new byte[2];

        System.arraycopy(bytes, 0, resultBytes, 0, bytes.length - 2);
        System.arraycopy(bytes, bytes.length - 2, statusBytes, 0, 2);

        Log.w(TAG, ACR35Controller.bytesToHex(statusBytes));

        buffer.append(ACR35Controller.bytesToHex(resultBytes));
        buffer.append("");

        return buffer.toString();
    }

    private static String runCommand(IsoDep isoDep, String command) throws IOException {
        return parseResult(isoDep.transceive(ACR35Controller.hexToBytes(command)));
    }

    @Override
    public boolean execute(String action, final JSONArray data, CallbackContext callbackContext) throws
            JSONException {
        final String _action = action;
        final CallbackContext _callbackContext = callbackContext;

        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                String techAction = cordova.getActivity().getIntent().getAction();
                if (NfcAdapter.ACTION_TECH_DISCOVERED.equals(techAction)) {
                    Tag tagFromIntent = cordova.getActivity().getIntent().getParcelableExtra(NfcAdapter.EXTRA_TAG);
                    Log.i(TAG, Arrays.toString(tagFromIntent.getTechList()));

                    IsoDep isoDep = IsoDep.get(tagFromIntent);

                    String atr = parseResult( isoDep.getHistoricalBytes());
                    Log.i(TAG, atr);

                    final String loadKeyCommand = "FF 82 00 00 06 %s";
                    final String authCommand = "FF 86 00 00 05 01 00 %s 60 00";
                    final String defaultKey = "FF FF FF FF FF FF";
                    String authKeyCommand = "FF 86 00 00 05 01 00 00 60 00";

                    StringBuilder result = new StringBuilder();

                    try {
                        if(_action.equals("readIdFromTag")) {
                            result.append(runCommand(isoDep, "FFCA000000"));
                        }
                        if (_action.equals("readDataFromTag")) {
                            result.append(runCommand(isoDep, String.format(loadKeyCommand, defaultKey)));
                            result.append(runCommand(isoDep, String.format(authCommand, "04")));
                            result.append(runCommand(isoDep, "FFB0000410"));
                            result.append(runCommand(isoDep, "FFB0000510"));
                            result.append(runCommand(isoDep, "FFB0000610"));
                            result.append(runCommand(isoDep, String.format(authCommand, "08")));
                            result.append(runCommand(isoDep, "FFB0000810"));
                            result.append(runCommand(isoDep, "FFB0000910"));
                            result.append(runCommand(isoDep, "FFB0000A10"));
                            result.append(runCommand(isoDep, String.format(authCommand, "10")));
                            result.append(runCommand(isoDep, "FFB0001010"));
                            result.append(runCommand(isoDep, "FFB0001110"));
                            result.append(runCommand(isoDep, "FFB0001210"));
                        }
                        if (_action.equals("writeDataIntoTag")) {
                            try {
                                String dataString = data.get(0).toString();
                                byte[] dataToWrite = new byte[128];
                                Arrays.fill(dataToWrite, (byte)0);
                                byte[] dataBytes = ACR35Controller.hexToBytes(dataString);
                                System.arraycopy(dataBytes, 0, dataToWrite, 0, dataBytes.length);

                                String dataStringToWrite = ACR35Controller.bytesToHex(dataToWrite).replaceAll("\\s","");
                                String commandString1 = "FF D6 00 04 30"+ dataStringToWrite.substring(0, 95);
                                String commandString2 = "FF D6 00 08 30"+ dataStringToWrite.substring(96, (96*2)-1);
                                String commandString3 = "FF D6 00 10 20"+ dataStringToWrite.substring(96*2, (96*2+64)-1);

                                Log.w(TAG, dataStringToWrite);

                               result.append(runCommand(isoDep, String.format(loadKeyCommand, defaultKey)));
                               result.append(runCommand(isoDep, String.format(authCommand, "04")));
                               result.append(runCommand(isoDep, commandString1));
                               result.append(runCommand(isoDep, String.format(authCommand, "08")));
                               result.append(runCommand(isoDep, commandString2));
                               result.append(runCommand(isoDep, String.format(authCommand, "10")));
                               result.append(runCommand(isoDep, commandString3));

                            } catch (java.lang.Exception e) {
                                Log.w(TAG, e);
                            }
                        }


                        JSONArray resultArray = new JSONArray();
                        resultArray.put(result.toString().replaceAll("\\s", ""));
                        resultArray.put(atr.replaceAll("\\s", ""));

                        PluginResult dataResult = new PluginResult(PluginResult.Status.OK,  resultArray);
                        _callbackContext.sendPluginResult(dataResult);
                    } catch (Exception ex) {
                        Log.w(TAG, ex);
                    }

                }
            }

        });

        PluginResult dataResult = new PluginResult(PluginResult.Status.OK, "IGNORE");
        dataResult.setKeepCallback(true);

        _callbackContext.sendPluginResult(dataResult);

        return true;
    }
}
