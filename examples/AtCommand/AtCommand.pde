/**
 * Copyright (c) 2009 Andrew Rapp. All rights reserved.
 *
 * This file is part of XBee-Arduino.
 *
 * XBee-Arduino is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * XBee-Arduino is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with XBee-Arduino.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <XBee.h>
#include <SoftwareSerial.h>

/*
This example is for Series 1 (10C8 or later firmware) or Series 2 XBee radios
Sends a few AT command queries to the radio and checks the status response for success

This example uses the SoftSerial library to view the XBee communication.  I am using a
Modern Device USB BUB board (http://moderndevice.com/connect) and viewing the output
with the Arduino Serial Monitor.
*/

// Define SoftSerial TX/RX pins
// Connect Arduino pin 8 to TX of usb-serial device
uint8_t ssRX = 8;
// Connect Arduino pin 9 to RX of usb-serial device
uint8_t ssTX = 9;
// Remember to connect all devices to a common Ground: XBee, Arduino and USB-Serial device
// SoftwareSerial Serial(ssRX, ssTX);

XBee xbee = XBee();

// serial high
uint8_t shCmd[] = {'S','H'};
// serial low
uint8_t slCmd[] = {'S','L'};
// association status
uint8_t assocCmd[] = {'A','I'};
// node identifier
uint8_t nodeCmd[] = {'N','I'};

AtCommandRequest atRequest = AtCommandRequest(shCmd);

AtCommandResponse atResponse = AtCommandResponse();

#define BUFF_MAX 16
char buff[BUFF_MAX];

void setup() {
  Serial3.begin(57600);
  xbee.begin(Serial3);
  // start soft serial
  Serial.begin(115200);

  Serial.println("Startup, delaying by a few second(s).");
  // Startup delay to wait for XBee radio to initialize.
  // you may need to increase this value if you are not getting a response
  delay(1000);
}

void loop() {

  // get SH
  sendAtCommand();

  // set command to SL
  atRequest.setCommand(slCmd);
  sendAtCommand();

  // set command to AI
  atRequest.setCommand(assocCmd);
  sendAtCommand();

  // set node
  atRequest.setCommand(nodeCmd);
  sendAtCommand();

  // we're done.  Hit the Arduino reset button to start the sketch over
  while (1) {};
}

void sendAtCommand() {
  Serial.println("Sending command to the XBee");

  // send the command
  xbee.send(atRequest);

  // wait up to 5 seconds for the status response
  if (xbee.readPacket(5000)) {
    // got a response!

    // should be an AT command response
    if (xbee.getResponse().getApiId() == AT_COMMAND_RESPONSE) {
      xbee.getResponse().getAtCommandResponse(atResponse);

      if (atResponse.isOk()) {
        Serial.print("Command [");
        Serial.write(atResponse.getCommand()[0]);
        Serial.write(atResponse.getCommand()[1]);
        Serial.println("] was successful!");

        if (atResponse.getValueLength() > 0) {
          Serial.print("Command value length: ");
          Serial.println(atResponse.getValueLength(), DEC);

          Serial.print("Command value: ");

          for (int i = 0; i < atResponse.getValueLength(); i++) {
            Serial.print(atResponse.getValue()[i], HEX);
            Serial.print(" ");
          }
          Serial.println();

          if (atResponse.getValueLength() > 4) {
            Serial.print("String value: ");

            for (int i = 0; i < atResponse.getValueLength(); i++) {
              Serial.write(atResponse.getValue()[i]);
            }
          }
        }
      }
      else {
        Serial.print("Command return error code: ");
        Serial.println(atResponse.getStatus(), HEX);
      }
    } else {
      Serial.print("Expected AT response but got ");
      Serial.print(xbee.getResponse().getApiId(), HEX);
    }
  } else {
    // at command failed
    if (xbee.getResponse().isError()) {
      Serial.print("Error reading packet.  Error code: ");
      Serial.println(xbee.getResponse().getErrorCode());
    }
    else {
      Serial.print("No response from radio");
    }
  }
}

void printHex(uint8_t *data, uint8_t length)
{
  snprintf(buff, BUFF_MAX, "%d", data[0]);

  Serial.print("Name Data: ");
  Serial.println(buff);
}

void PrintHex8(uint8_t *data, uint8_t length) // prints 8-bit data in hex
{
     char tmp[length*2+1];
     byte first;
     byte second;
     for (int i=0; i<length; i++) {
           first = (data[i] >> 4) & 0x0f;
           second = data[i] & 0x0f;
           // base for converting single digit numbers to ASCII is 48
           // base for 10-16 to become lower-case characters a-f is 87
           // note: difference is 39
           tmp[i*2] = first+48;
           tmp[i*2+1] = second+48;
           if (first > 9) tmp[i*2] += 39;
           if (second > 9) tmp[i*2+1] += 39;
     }
     tmp[length*2] = 0;
     Serial.print(tmp);
}
