# ----------------------------------------------------------------------
#
#    Dockerfile script -- This file is part of the Power Monitoring
#    Solution. It contains all the commands needed to assemble an image 
#    of the current sensing service on a Raspberry Pi with Raspberry Pi OS.
#
#    Copyright (C) 2025  DataImage
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, version 3 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see https://www.gnu.org/licenses/.
#
# ----------------------------------------------------------------------

FROM python:3.9

COPY ./requirements.txt /
RUN pip3 install -r requirements.txt
WORKDIR /app
ADD ./code/ /app
RUN python utilities/generate_local_requirements.py && pip3 install -r generated_requirements.txt

CMD [ "python3", "/app/main.py"]
