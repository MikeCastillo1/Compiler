/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * log.vala
 * Copyright (C) 2015 zeta <kmsiete@gmail.com>
 *
 * compiler is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * compiler is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Compiler{
	public class Log {
		 //properties
		private bool verbose = true;

		public Log (bool verbose = false){
			this.verbose = verbose;
		}

		public void mlc(string TAG, string message,int line, int column){
		    if (this.verbose){
		        stdout.printf("In :"+TAG+" <%d,%d> ::> %s \n",line,column,message);
		    }
		}

		public void m(string TAG, string message){
		    if (this.verbose){
		        stdout.printf("In :"+TAG+"::> %s\n",message);
		    }
		}
	}
}

