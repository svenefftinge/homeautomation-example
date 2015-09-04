package org.xtext.homeautomation.tests

import com.google.inject.Inject
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.junit4.validation.ValidationTestHelper
import org.junit.Test
import org.junit.runner.RunWith
import org.xtext.homeautomation.RulesInjectorProvider
import org.xtext.homeautomation.rules.Model
import org.xtext.homeautomation.rules.RulesPackage
import org.xtext.homeautomation.validation.RulesValidator

@RunWith(XtextRunner)
@InjectWith(RulesInjectorProvider)
class ParserTest {
	
	@Inject extension ParseHelper<Model>
	@Inject ValidationTestHelper validator
	@Inject IGenerator generator
	
	
	@Test def void testRecursion() {
		val model = '''
			Device Window can be opened, closed
			Device Heating can be on, off
			
			Rule 'Close the window when the heating is on' 
				when Heating.on
				then Window.closed
			
			Rule 'Recursion' 
				when Window.closed
				then Heating.on
		'''.parse
		validator.assertError(model, RulesPackage.Literals.RULE, RulesValidator.RECURSION)
	}
	
	@Test def void testRecursion_01() {
		val model = '''
			Device Window can be opened, closed
			Device Heating can be on, off
			
			Rule 'Close the window when the heating is on' 
				when Heating.on
				then Window.closed
			
			Rule 'Recursion' 
				when Window.closed
				then Window.opened
				
			Rule 'Recursion1' 
				when Window.opened
				then Heating.on
		'''.parse
		validator.assertError(model, RulesPackage.Literals.RULE, RulesValidator.RECURSION)
	}
	
	@Test def void testSimpleFile() {
		val model = '''
			Device Window can be opened, closed
			Device Heating can be on, off
			
			Rule 'Close the window when the heating is on' 
				when Heating.on
				then Window.closed
			
			Rule 'Turn off heating when window gets opened' 
				when Window.opened
				then Heating.off
		'''.parse
		
		validator.assertNoErrors(model)
		val fsa = new InMemoryFileSystemAccess 
		generator.doGenerate(model.eResource, fsa)
		fsa.allFiles.values.head.toString.contains('''
			public static void fire(String event) {
				if (event.equals("opened")) {
					System.out.println("Window is now opened!");
				}
				if (event.equals("closed")) {
					System.out.println("Window is now closed!");
				}
				if (event.equals("on")) {
					System.out.println("Heating is now on!");
				}
				if (event.equals("off")) {
					System.out.println("Heating is now off!");
				}
				if (event.equals("on")) {
					fire("closed");
				}
				if (event.equals("opened")) {
					fire("off");
				}
			}
		''')
	}
	
}