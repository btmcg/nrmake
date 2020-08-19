#￼Copyright(c) 2020-present, Brian McGuire.
# Distributed under the BSD-2-Clause
# (http://opensource.org/licenses/BSD-2-Clause)


%.o: %.c
	$(CC) $(CFLAGS) $(__local_cflags) $(CPPFLAGS) $(__local_cppflags) $(TARGET_ARCH) -c -o $@ $<

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(__local_cxxflags) $(CPPFLAGS) $(__local_cppflags) $(TARGET_ARCH) -c -o $@ $<

%.d: %.c
	$(CC) -MM $(CFLAGS) $(__local_cflags) $(CPPFLAGS) $(__local_cppflags) $(TARGET_ARCH) $< -o $@

%.d: %.cpp
	$(CXX) -MM $(CXXFLAGS) $(__local_cxxflags) $(CPPFLAGS) $(__local_cppflags) $(TARGET_ARCH) $< -o $@
