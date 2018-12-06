/*
* 
* Copyright (c) 2008-2010 Lu Aye Oo
* 
* @author 		Lu Aye Oo
* 
* http://code.google.com/p/flash-console/
* 
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
* 
*/
package com.junkbyte.console.core
{
	import com.junkbyte.console.Console;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	[Event(name="CONNECT", type="flash.events.Event")]
	/**
	 * @private
	 */
	public class Remoting extends ConsoleCore
	{
		
		public static const NONE:uint = 0;
		public static const SENDER:uint = 1;
		
		private var _mode:uint;
		private var _socket:Socket;
		private var _sendBuffer:ByteArray = new ByteArray();
		
		public function Remoting(m:Console)
		{
			super(m);
		}
		
		public function update():void
		{
			if (_sendBuffer.length)
			{
				if (_socket && _socket.connected)
				{
					_socket.writeBytes(_sendBuffer);
					_socket.flush();
					_sendBuffer = new ByteArray();
				}
				else
				{
					_sendBuffer = new ByteArray();
				}
			}
		}
		
		public function send(arg:ByteArray):Boolean
		{
			if (_mode == NONE) return false;
			_sendBuffer.position = _sendBuffer.length;
			_sendBuffer.writeBytes(arg);
			return true;
		}
		
		public function get remoting():uint
		{
			return _mode;
		}
		
		public function get canSend():Boolean
		{
			return _mode == SENDER;
		}
		
		public function set remoting(newMode:uint):void
		{
			if (newMode == _mode) return;
			if (newMode == SENDER)
			{
				_sendBuffer = new ByteArray();
				report("<b>Remoting started.</b> ", -1);
			}
			_mode = newMode;
			console.panels.updateMenu();
		}
		
		public function remotingSocket(host:String, port:int = 0):void
		{
			if (_socket && _socket.connected)
			{
				_socket.close();
				_socket = null;
			}
			if (host && port)
			{
				remoting = SENDER;
				report("Connecting to socket " + host + ":" + port);
				_socket = new Socket();
				_socket.addEventListener(Event.CLOSE, socketCloseHandler);
				_socket.addEventListener(Event.CONNECT, socketConnectHandler);
				_socket.addEventListener(IOErrorEvent.IO_ERROR, socketIOErrorHandler);
				_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socketSecurityErrorHandler);
				_socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
				_socket.connect(host, port);
			}
		}
		
		private function socketCloseHandler(e:Event):void
		{
			if (e.currentTarget == _socket)
			{
				_socket = null;
			}
		}
		
		private function socketConnectHandler(e:Event):void
		{
			report("Remoting socket connected.", -1);
			_sendBuffer = new ByteArray();
			sendLoginSuccess();
		}
		
		private function socketIOErrorHandler(e:Event):void
		{
			report("Remoting socket error." + e, 9);
			remotingSocket(null);
		}
		
		private function socketSecurityErrorHandler(e:Event):void
		{
			report("Remoting security error." + e, 9);
			remotingSocket(null);
		}
		
		private function socketDataHandler(e:Event):void
		{
			handleSocket(e.currentTarget as Socket);
		}
		
		public function handleSocket(socket:Socket):void
		{
			_socket = socket;
		}
		
		private function sendLoginSuccess():void
		{
			dispatchEvent(new Event(Event.CONNECT));
		}
	}
}